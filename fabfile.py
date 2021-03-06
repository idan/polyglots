import json
import os
from collections import OrderedDict

from unipath import Path
from pyquery import PyQuery as pq
from dulwich.repo import Repo
from dulwich.errors import NotGitRepository
from fabric.api import task, local, lcd

try:
    REPOS_PATH = Path(os.environ['POLYGLOTS_REPOS'])
except KeyError:
    REPOS_PATH = None


@task()
def scrape():
    """ Scrape the top 200 repo names for the top 10 languages """
    # The most popular languages on github
    # Taken from https://github.com/languages on Feb 9 2013
    languages = OrderedDict([
        ('JavaScript', []),
        ('Ruby', []),
        ('Java', []),
        ('Python', []),
        ('Shell', []),
        ('PHP', []),
        ('C', []),
        ('C++', []),
        ('Perl', []),
        ('Objective-C', []),
    ])
    most_watched_templ = 'https://github.com/languages/{}/most_watched?page={}'

    for lang, repos in languages.items():
        print('Fetching {}...'.format(lang))
        for i in xrange(1, 11):
            print('page {}'.format(i))
            d = pq(most_watched_templ.format(lang, i))
            repos.extend([a.attrib['href'].lstrip('/') for a in d('h3>a')])

    with open('most_watched_repos.json', 'w') as fp:
        json.dump(languages.items(), fp, indent=4)


@task()
def clone(lang=None):
    """ Clone the most-watched repos for all or some languages """
    do(clone_lang, lang)


@task()
def prune(lang=None):
    """ Prune repos that aren't in the most-watched list anymore """
    do(prune_lang, lang)


@task()
def verify(lang=None):
    """ Verify that repos are present and correct """
    do(verify_lang, lang)


def load_repos():
    with open('most_watched_repos.json', 'r') as fp:
        languages = OrderedDict(json.load(fp))
    return languages


def do(func, lang=None):
    """ Do something with some or all repos """
    if not REPOS_PATH:
        print "No REPOS_PATH env var set, I don't know where the repos are!"
        print "Aborting..."
        return
    languages = load_repos()
    if lang and lang in languages:
        func(lang, languages[lang])
    for lang, repos in languages.items():
        func(lang, repos)


def clone_lang(lang, repos):
    """ Clone the most-watched repos for a given language """
    print('*** Cloning {} repositories...'.format(lang))
    langpath = REPOS_PATH.child(lang)
    local('mkdir -p {}'.format(langpath))
    for r in repos:
        user, reponame = r.split('/')
        userpath = langpath.child(user)
        repopath = userpath.child(reponame)
        if repopath.exists():
            print('Skipping {}...'.format(r))
            continue
        print('Cloning {}'.format(r))
        local('mkdir -p {}'.format(userpath))
        with lcd(userpath):
            local('git clone https://github.com/{}.git'.format(r))


def verify_lang(lang, repos):
    """ Verify the most-watched repos for a given language """
    print('*** Verifying {} repositories...'.format(lang))
    for r in repos:
        user, reponame = r.split('/')
        path = REPOS_PATH.child(lang, user, reponame)
        if not path.exists():
            print('Missing: {}'.format(r))
            continue
        try:
            r = Repo(path)
        except NotGitRepository:
            print('Corrupt: {}'.format(r))


def prune_lang(lang, repos):
    print('Pruning {} repositories...'.format(lang))
    usermap = {}
    for r in repos:
        user, reponame = r.split('/')
        if user in usermap:
            usermap[user].append(reponame)
        else:
            usermap[user] = [reponame]
    for user, repos in usermap.items():
        path = REPOS_PATH.child(lang, user)
        if not path.exists():
            continue
        else:
            subdirs = path.listdir(names_only=True)
            to_delete = set(subdirs) - set(repos)
            for d in to_delete:
                print("To delete: {}/{}".format(user, to_delete))


@task()
def launch_ec2(instancetype='m1.small'):
    """ Launch an ec2 instance """
    userdata = Path().child("aws_bootstrap.sh")
    try:
        EC2_KEYPAIR_NAME = Path(os.environ['EC2_KEYPAIR_NAME'])
    except KeyError:
        print('EC2_KEYPAIR_NAME environment variable not set! I need that to work.')
        print('Aborting...')
        return

    cmd = 'ec2run ami-0cdf4965 -b /dev/sdc=snap-5b613818 -t {instancetype} -k {keypair} -f {userdata} --instance-initiated-shutdown-behavior terminate'
    local(cmd.format(instancetype=instancetype, keypair=EC2_KEYPAIR_NAME, userdata=userdata))
