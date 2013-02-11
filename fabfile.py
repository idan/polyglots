import json
import os
from pyquery import PyQuery as pq
from collections import OrderedDict

from fabric.api import task, local, lcd

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


def clone_lang(lang, repos):
    """ Clone the most-watched repos for a given language """
    print('Cloning {} repositories...'.format(lang))
    local('mkdir -p repos/{}'.format(lang))
    for r in repos:
        user, reponame = r.split('/')
        userpath = 'repos/{}/{}'.format(lang, user)
        repopath = '#{userpath}/{#reponame}'
        if os.path.exists(os.path.join(os.getcwd(), repopath)):
            print('Skipping {}...'.format(r))
            continue
        print('Cloning {}'.format(r))
        local('mkdir -p {}'.format(userpath))
        with lcd(userpath):
            local('git clone https://github.com/{}.git'.format(r))


@task()
def clone():
    """ Clone the most-watched repos for all languages """
    with open('most_watched_repos.json', 'r') as fp:
        languages = OrderedDict(json.load(fp))
    for lang, repos in languages.items():
        clone_lang(lang, repos)
