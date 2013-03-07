from __future__ import absolute_import

import os
import re
import pymongo
from bson import ObjectId
import requests
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

github_auth_payload = {
    'client_id': os.environ['GITHUB_CLIENT_ID'],
    'client_secret': os.environ['GITHUB_CLIENT_SECRET'],
}

github_contributors_url = 'https://api.github.com/repos/{user}/{repo}/contributors'
github_user_url = 'https://api.github.com/users/{user}'


@celery.task
def index_user(oid):
    doc = db.authors.find_one({'_id': ObjectId(oid)})
    if doc is None:
        print("author not found? {}".format(oid))
        return


@celery.task(rate_limit='12500/h', default_retry_delay=5*60)
def get_contributors(user, repo):
    url = github_contributors_url.format(user=user, repo=repo)
    try:
        r = requests.get(url,
                         params=github_auth_payload)
    except RequestException as exc:
        delay_seconds = 2**get_contributors.request.retries
        raise get_contributors.retry(exc=exc,
                                     countdown=delay_seconds)

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
