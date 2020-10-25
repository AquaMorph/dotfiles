#!/usr/bin/env python3

# Python wrapper for REST API for Home Assistant.

from requests import get, post
import json

class HomeAssistant(object):
    def __init__(self, ip, token):
        self.url = 'http://{}:8123'.format(ip)
        self.headers = {
            'Authorization': 'Bearer {}'.format(token),
            'content-type': 'application/json',
        }
    def postService(self, domain, service, data):
        response = post("{}/api/services/{}/{}".format(self.url, domain, service),
                        headers=self.headers, data=json.dumps(data))
        response.raise_for_status()
        return response
    def getRequest(self, domain, data):
        response = get("{}/api/{}".format(self.url, domain),
                        headers=self.headers, data=json.dumps(data))
        return json.loads(response.text)
    def getServices(self):
        return self.getRequest('services', '')
    def runScene(self, entityId):
        data = {'entity_id': entityId}
        self.postService('scene', 'turn_on', data)
