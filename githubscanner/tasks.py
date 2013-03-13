from __future__ import absolute_import

import os
import sys
import re
from collections import Counter
import pymongo
from bson import ObjectId
import requests
import iso8601
from requests.exceptions import RequestException

from githubscanner.celery import celery

# Setup mongodb
if 'MONGOHQ_URL' not in os.environ:
    raise Exception('You must provide a mongo connection URL.')
MONGOHQ_URL = os.environ['MONGOHQ_URL']
MONGO_DB_NAME = MONGOHQ_URL.split('/')[-1]
conn = pymongo.Connection(host=MONGOHQ_URL)
db = conn[MONGO_DB_NAME]

re_email = re.compile('([\w\-\.]+@(?:\w[\w\-]+\.)+[\w\-]+)')
re_rel = re.compile(r'<(?P<url>\S+)>; rel="(?P<rel>\w+)"')

github_auth_payload = {
    'client_id': os.environ['GITHUB_CLIENT_ID'],
    'client_secret': os.environ['GITHUB_CLIENT_SECRET'],
}

github_contributors_url = 'https://api.github.com/repos/{user}/{repo}/contributors'
github_user_url = 'https://api.github.com/users/{user}'
github_user_repos_url = 'https://api.github.com/users/{user}/repos'
github_repo_url = 'https://api.github.com/repos/{user}/{repo}'

def parse_links(text):
    """Parse the github 'link' header for rel=next/prev/first/last URLs"""
    d = {}
    if not text:
        return d
    for chunk in text.split(','):
        chunk = chunk.strip()
        match = re_rel.match(chunk).groupdict()
        d[match['rel']] = match['url']
    return d


@celery.task
def index_user(oid):
    doc = db.authors.find_one({'_id': ObjectId(oid)})
    if doc is None:
        print("author not found? {}".format(oid))
        return


@celery.task(rate_limit='12500/h', default_retry_delay=5*60)
def get_contributors(user, repo):
    url = github_contributors_url.format(user=user, repo=repo)
    delay_seconds = 2**get_contributors.request.retries
    try:
        r = requests.get(url,
                         params=github_auth_payload)
    except RequestException as exc:
        raise get_contributors.retry(exc=exc,
                                     countdown=delay_seconds)

    if not r.ok:
        raise get_contributors.retry(countdown=delay_seconds)

    raw = r.json()
    contributors = {}
    for record in raw:
        contributors[record['login']] = record['contributions']
    db.repos.update({'user': user, 'name': repo},
                    {'$set': {
                        'contributors': contributors,
                        'contributor_count': len(contributors)
                    }})


@celery.task(rate_limit='12500/h', default_retry_delay=5*60)
def get_github_user(user):
    url = github_user_url.format(user=user)
    try:
        r = requests.get(url,
                         params=github_auth_payload)
    except RequestException as exc:
            delay_seconds = 2**get_contributors.request.retries
            raise get_contributors.retry(exc=exc,
                                         countdown=delay_seconds)
    raw = r.json()
    copy_props = ['type', 'name', 'company', 'blog', 'location', 'email',
                  'hireable', 'public_repos', 'followers', 'following',
                  'created_at', 'updated_at', 'public_gists']
    doc = {}
    for prop in copy_props:
        if prop in raw:
            doc[prop] = raw[prop]

    db.contributors.update({'login': user}, {'$set': doc})


@celery.task(rate_limit='12500/h', default_retry_delay=5*60)
def get_user_repos(user, url=None):
    # in case something goes wrong
    delay_seconds = 2**get_user_repos.request.retries

    # get the contributor from the db, skip if no public repos
    contrib = db.contributors.find_one({'login': user}, fields=['public_repos'])
    if contrib['public_repos'] == 0:
        print('No repos for "{}"!'.format(user))
        return

    payload = github_auth_payload.copy()
    payload['per_page'] = 100
    if url is None:
        url = github_user_repos_url.format(user=user)

    try:
        r = requests.get(url, params=payload)
    except RequestException as exc:
        raise get_user_repos.retry(exc=exc, countdown=delay_seconds)

    raw = r.json()

    if type(raw) != list:
        raise get_user_repos.retry(countdown=delay_seconds)

    if len(raw) > 0 and 'full_name' not in raw[0]:
        raise get_user_repos.retry(countdown=delay_seconds)

    # massage the repo info
    repos = []
    for repo in raw:
        copy_props = ['name', 'full_name', 'description', 'fork', 'created_at',
                      'updated_at', 'pushed_at', 'homepage', 'size',
                      'watchers_count', 'language', 'has_issues',
                      'has_downloads', 'has_downloads', 'forks_count',
                      'open_issues_count', 'forks', 'open_issues', 'watchers',
                      'master_branch', 'default_branch']
        massaged = {}
        for prop in copy_props:
            if prop in repo:
                massaged[prop] = repo[prop]

        massaged['owner'] = {
            'login': repo['owner']['login'],
            'type': repo['owner']['type'],
        }
        repos.append(massaged)

    if len(repos) == 1:
        doc = {
            '$push': {'repos': repos[0]}
        }
    else:
        doc = {
            '$push': {'repos': {'$each': repos}}
        }

    if 'link' in r.headers:
        links = parse_links(r.headers['link'])
        if 'next' in links:
            get_user_repos.delay(user, url=links['next'])
        else:
            # all finished!
            doc['$set'] = {'repos_fetched': True}
    else:
        # all finished!
        doc['$set'] = {'repos_fetched': True}

    db.contributors.update({'login': user}, doc)


def ranked_language_contributions():
    """
    Annotate contributors with the languages of the ranked repositories they
    have contributed to.
    """

    # Total number of ranked repositories committed to, by language
    contributor_lang_freq = {}

    # Total number of commits to ranked repos, by language
    contributor_langcommit_freq = {}

    for repo in db.repos.find(fields=['user', 'name', 'contributors', 'language']):
        sys.stdout.write('Processing "{}/{}"... '.format(
            repo['user'], repo['name']))
        language = repo['language']
        if 'contributors' not in repo:
            print("No contributors!")
            continue
        contributors = repo['contributors']
        for login, commits in contributors.items():
            if login not in contributor_lang_freq:
                contributor_lang_freq[login] = Counter()
            if login not in contributor_langcommit_freq:
                contributor_langcommit_freq[login] = Counter()
            contributor_lang_freq[login][language] += 1
            contributor_langcommit_freq[login][language] += commits

        print('indexed {} contributors'.format(len(contributors)))

    logins = contributor_lang_freq.keys()
    for login in logins:
        sys.stdout.write('Annotating "{}"... '.format(login))
        db.contributors.update({'login': login}, {'$set': {
            'ranked_repos_by_language': contributor_lang_freq[login],
            'ranked_repos_by_language_commits': contributor_langcommit_freq[login],
        }})
        print('Done!')


def get_repo_timestamps(user, repo):
    sys.stdout.write("Fetching timestamps for {}/{}... ".format(user, repo))
    url = github_repo_url.format(user=user, repo=repo)
    try:
        r = requests.get(url,
                         params=github_auth_payload)
    except RequestException:
        print("************** TOTAL FAIL **************")

    raw = r.json()
    fields = ['created_at', 'updated_at', 'pushed_at']
    doc = {}
    for f in fields:
        if f not in raw:
            print ("*** Broken repo. Skipping!")
            return
        doc[f] = iso8601.parse_date(raw[f])
    db.repos.update({'user': user, 'name': repo},
                    {'$set': doc})
    print("OK!")
