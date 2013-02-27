import os
import json
from unipath import FSPath as Path
from dulwich.repo import Repo
import pymongo
from collections import OrderedDict

# Where the repos at on our disk?
REPOS_PATH = Path(os.environ['POLYGLOTS_REPOS'])

# Get the canonical list of repos
with open('most_watched_repos.json', 'r') as fp:
    LANGUAGES = OrderedDict(json.load(fp))

# Setup mongodb
if 'MONGOHQ_URL' not in os.environ:
    raise Exception('You must provide a mongo connection URL.')
MONGOHQ_URL = os.environ['MONGOHQ_URL']
MONGO_DB_NAME = MONGOHQ_URL.split('/')[-1]
conn = pymongo.Connection(host=MONGOHQ_URL)
db = conn[MONGO_DB_NAME]


class Repository:
    """ Encapsulates repo metadata in one handy class. """
    def __init__(self, lang, rank, identifier):
        self.identifier = identifier
        self.user, self.name = self.identifier.split('/')
        self.lang = lang
        self.rank = rank
        self.path = REPOS_PATH.child(self.lang, self.user, self.name)
        self.repo = Repo(self.path)  # the dulwich Repo class instance

    def __unicode__(self):
        return unicode(self.identifier)

    def __str__(self):
        return self.identifier


def walk_repos(*methods):
    """ Iterate over all the repositories, calling methods on each one. """
    langindex = 0
    for lang, repos in LANGUAGES.items():
        print("==== {} ====".format(lang))
        repoindex = 0
        for r in repos:
            print ('== processing {} {} ({}:{})'.format(lang, r, langindex, repoindex))
            repo = Repository(lang, repoindex, r)
            for m in methods:
                print('= executing "{}"...'.format(m.func_name()))
                m(repo)
            repoindex += 1
        langindex += 1
