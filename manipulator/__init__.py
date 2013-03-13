import os
import sys
import copy
from collections import OrderedDict
import csv
import json
import pymongo

# Setup mongodb
if 'MONGOHQ_URL' not in os.environ:
    raise Exception('You must provide a mongo connection URL.')
MONGOHQ_URL = os.environ['MONGOHQ_URL']
MONGO_DB_NAME = MONGOHQ_URL.split('/')[-1]
conn = pymongo.Connection(host=MONGOHQ_URL)
db = conn[MONGO_DB_NAME]

langs = ['JavaScript', 'Ruby', 'Java', 'Python', 'Shell',
         'PHP', 'C', 'C++', 'Perl', 'Objective-C']

counts = [
    ('JavaScript', 0),
    ('Ruby', 0),
    ('Java', 0),
    ('Python', 0),
    ('Shell', 0),
    ('PHP', 0),
    ('C', 0),
    ('C++', 0),
    ('Perl', 0),
    ('Objective-C', 0),
]


def adjacency_matrix():
    """
    Calculate a language adjacency matrix for the contributors to the
    ranked repositories.
    """
    lang_devs = OrderedDict([
        ('JavaScript', OrderedDict(counts)),
        ('Ruby', OrderedDict(counts)),
        ('Java', OrderedDict(counts)),
        ('Python', OrderedDict(counts)),
        ('Shell', OrderedDict(counts)),
        ('PHP', OrderedDict(counts)),
        ('C', OrderedDict(counts)),
        ('C++', OrderedDict(counts)),
        ('Perl', OrderedDict(counts)),
        ('Objective-C', OrderedDict(counts)),
    ])

    lang_repos = OrderedDict([
        ('JavaScript', OrderedDict(counts)),
        ('Ruby', OrderedDict(counts)),
        ('Java', OrderedDict(counts)),
        ('Python', OrderedDict(counts)),
        ('Shell', OrderedDict(counts)),
        ('PHP', OrderedDict(counts)),
        ('C', OrderedDict(counts)),
        ('C++', OrderedDict(counts)),
        ('Perl', OrderedDict(counts)),
        ('Objective-C', OrderedDict(counts)),
    ])

    lang_commits = OrderedDict([
        ('JavaScript', OrderedDict(counts)),
        ('Ruby', OrderedDict(counts)),
        ('Java', OrderedDict(counts)),
        ('Python', OrderedDict(counts)),
        ('Shell', OrderedDict(counts)),
        ('PHP', OrderedDict(counts)),
        ('C', OrderedDict(counts)),
        ('C++', OrderedDict(counts)),
        ('Perl', OrderedDict(counts)),
        ('Objective-C', OrderedDict(counts)),
    ])

    for c in db.contributors.find(fields=[
            'login',
            'ranked_repos_by_language',
            'ranked_repos_by_language_commits']):

        sys.stdout.write('Processing "{}"... '.format(c['login']))
        for tallylang, tally in lang_devs.items():
            if tallylang in c['ranked_repos_by_language']:
                for lang in c['ranked_repos_by_language'].keys():
                    tally[lang] += 1
        for tallylang, tally in lang_repos.items():
            if tallylang in c['ranked_repos_by_language']:
                for lang, num_repos in c['ranked_repos_by_language'].items():
                    tally[lang] += num_repos
        for tallylang, tally in lang_commits.items():
            if tallylang in c['ranked_repos_by_language_commits']:
                for lang, num_commits in c['ranked_repos_by_language_commits'].items():
                    tally[lang] += num_commits
        print("Done!")

    people = [l.values() for l in lang_devs.values()]
    repos = [l.values() for l in lang_repos.values()]
    commits = [l.values() for l in lang_commits.values()]
    people_noself = copy.deepcopy(people)
    repos_noself = copy.deepcopy(repos)
    commits_noself = copy.deepcopy(commits)
    for matrix in [people_noself, repos_noself, commits_noself]:
        remove_identity(matrix)
    return {
        'people': people,
        'repos': repos,
        'commits': commits,
        'people_noself': people_noself,
        'repos_noself': repos_noself,
        'commits_noself': commits_noself,
    }


def remove_identity(matrix):
    for i in xrange(len(matrix)):
        matrix[i][i] = 0


def dump_repo_data():
    meta_fields = ['_id', 'name', 'user', 'language']
    numeric_fields = ['rank', 'contributor_count', 'authors_count', 'forks_count', 'size', 'num_commits', 'watchers_count', 'disk_bytes']
    datetime_fields = ['latest_commit', 'oldest_commit', 'created_at']
    repos = list(db.repos.find(fields=meta_fields + numeric_fields + datetime_fields))
    for repo in repos:
        repo['_id'] = str(repo['_id'])
        for df in datetime_fields:
            if df in repo:
                repo[df] = repo[df].isoformat() + 'Z'

    fieldmap = OrderedDict()
    for f in meta_fields:
        fieldmap[f] = {'type': 'string'}
    for f in numeric_fields:
        # compute extents
        arr = sorted([r[f] for r in repos if f in r])
        extent = [arr[0], arr[-1]]
        fieldmap[f] = {'type': 'int', 'extents': extent}
    for f in datetime_fields:
        # compute extents
        arr = sorted([r[f] for r in repos if f in r])
        extent = [arr[0], arr[-1]]
        fieldmap[f] = {'type': 'datetime', 'extents': extent}

    with open('repos.csv', 'wb') as fp:
        writer = csv.DictWriter(fp, fieldmap.keys())
        writer.writeheader()
        for r in sorted(repos, key=repokey):
            writer.writerow(r)

    with open('repofields.json', 'w') as fp:
        json.dump(fieldmap, fp, indent=2)


def repokey(r):
    key = langs.index(r['language']) * 1000
    key += r['rank']
    return key
