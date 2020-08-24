import json
import os
import urllib.request

# getJSONData returns JSON data from Blackmagic Design's website.
def getJSONData():
    with urllib.request.urlopen('https://www.blackmagicdesign.com/api/support/us/downloads.json') as url:
        return json.loads(url.read().decode())

# getDownloads() returns a list of downloads.
def getDownloads():
    return getJSONData()['downloads']

# getResolveStudioDownloads() returns a list of DaVinci Resolve Studio downlaods.
def getResolveStudioDownloads():
    return [d for d in getDownloads() if 'davinci-resolve-and-fusion' in d['relatedFamilies'][0] and
            'Studio' in d['name'] and 'Resolve' in d['name']]

# filterOnlyLinuxSupport() filters a list of downloads to only ones that
# support Linux.
def filterOnlyLinuxSupport(downloads):
    return [d for d in downloads if 'Linux' in d['platforms']]

# getLinuxURL() returns the Linux download info.
def getLinuxURL(download):
    return download['urls']['Linux'][0]

# getURLId() returns the download id.
def getURLId(url):
    return url['downloadId']

# getURLVersion() returns the url version number.
def getURLVersion(url):
    return '{}.{}.{}'.format(url['major'], url['minor'], url['releaseNum'])

# getDownloadId() returns downlaod id hash.
def getDownloadId(download):
    return download['id']

for d in filterOnlyLinuxSupport(getResolveStudioDownloads()):
    linux = getLinuxURL(d)
    print(getURLVersion(linux), getURLId(linux), getDownloadId(d))
