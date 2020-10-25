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
        response = post("{}/api/services/{}/{}".format(self.url,
                                                       domain,
                                                       service),
                        headers=self.headers, data=json.dumps(data))
        response.raise_for_status()
        return response
    def getRequest(self, domain, data=''):
        response = get("{}/api/{}".format(self.url, domain),
                        headers=self.headers, data=json.dumps(data))
        return response.text

    # Returns a message if the API is up and running.
    def getAPI(self):
        return self.getRequest('')

    # Returns the current configuration
    def getConfig(self):
        return self.getRequest('config')

    # Returns basic information about the Home Assistant instance.
    def getDiscoveryInfo(self):
        return self.getRequest('discovery_info')

    # Returns an array of event objects. Each event object contains
    # event name and listener count.
    def getEvents(self):
        return self.getRequest('events')

    # Returns an array of service objects. Each object contains the
    # domain and which services it contains.
    def getServices(self):
        return self.getRequest('services')

    # Returns an array of state changes in the past. Each object contains
    # further details for the entities.
    def getHistory(self,
                   minimumResponse=False,
                   entityId='',
                   startTime='',
                   endTime='',
                   significantChangesOnly=False):
        options=''
        if startTime:
            options = '/' + startTime
        options += '?'
        if endTime:
            options += '&end_time=' + endTime
        if minimumResponse:
            options += '&minimal_response'
        if entityId:
            options += '&filter_entity_id=' + entityId
        if significantChangesOnly:
            options += '&significant_changes_only'
        return self.getRequest('history/period'+options)

    # Returns an array of logbook entries.
    def getLogbook(self, entityId='', startTime='', endTime=''):
        options=''
        if startTime:
            options = '/' + startTime
        options += '?'
        if endTime:
            options += '&end_time=' + endTime
        if entityId:
            options += '&entity=' + entityId
        return self.getRequest('logbook'+options)
    
    # Returns an array of state objects or  a state object for specified
    # entity_id. Each state has the following attributes: entity_id, state,
    # last_changed and attributes.
    def getState(self, entityId=''):
        if entityId:
            entityId = '/' + entityId
        return self.getRequest('states' + entityId)

    # Retrieve all errors logged during the current session of Home Assistant.
    def getErrorLog(self):
        return self.getRequest('error_log')

    # Returns the data (image) from the specified camera entity_id.
    def getCameraProxy(self, entityId):
        return self.getRequest('camera_proxy/' + entityId)
    
    def runScene(self, entityId):
        data = {'entity_id': entityId}
        self.postService('scene', 'turn_on', data)
