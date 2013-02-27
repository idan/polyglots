import datetime
from collections import Counter
from subprocess import check_output

from . import db

def update_mongo_repo(repo, doc):
    """ update/insert (upsert) a repo record in mongo """
    repos = db.repos
    repos.update(
        {'user': repo.user,
         'name': repo.name,
         'language': repo.lang,
         'rank': repo.rank,
         },
        {'$set': doc},
        upsert=True)


def analyze_commits(repo):
    try:
        commits = repo.repo.revision_history(repo.repo.head())
    except:
        print("* Bad repo: {} {}".format(repo.lang, repo.identifier))
        return

    doc = {}
    doc[u'num_commits'] = len(commits)
    oldest = commits[-1]
    latest = commits[0]
    doc[u'oldest_commit'] = datetime.datetime.utcfromtimestamp(oldest.commit_time)
    doc[u'latest_commit'] = datetime.datetime.utcfromtimestamp(latest.commit_time)
    update_mongo_repo(repo, doc)
    print("{} commits".format(doc['num_commits']))


def count_committers(repo):
    try:
        commits = repo.repo.revision_history(repo.repo.head())
    except:
        print("* Bad repo: {} {}".format(repo.lang, repo.identifier))
        return

    authors = [c.author for c in commits]
    counts = Counter()
    for a in authors:
        counts[a] += 1

    # not allowed to use periods in key names in mongodb!
    # break up authors into array of dicts
    doc = {
        u'authors_count': len(counts),
        u'authors': [{'name': k, 'commits': v} for k, v in counts.items()],
    }
    update_mongo_repo(repo, doc)
    print('{} distinct committers'.format(len(counts)))


def repo_size(repo):
    raw = check_output(["du", "-sb", repo.path])
    size = int(raw.split('\t')[0])
    update_mongo_repo(repo, {'disk_bytes': size})
    print('{} bytes'.format(repo, size))
