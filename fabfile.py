import json
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
        json.dump(languages, fp)

@task()
def clone(lang):
    """ Clone the most-watched repos for a given language """
    local('mkdir -p repos/{}'.format(lang))
    with open('most_watched_repos.json', 'r') as fp:
        repos = json.load(fp)
    for r in repos[lang]:
        user, reponame = r.split('/')
        repopath = 'repos/{}/{}'.format(lang, user)
        local('mkdir -p {}'.format(repopath))
        with lcd(repopath):
            local('git clone https://github.com/{}.git'.format(r))


