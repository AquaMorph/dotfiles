#!/usr/bin/env python3

# Program to create a photo checklist of a given frc event.

import configparser
import operator
import os
import tbapy
import todoist

# getProjectID() returns the project id that matches the name given.
def getProjectID(api, name):
    for project in api.state['projects']:
        if project['name'] == name:
            return project['id']
    print('Error: No project with the name {} found'.format(name))
    exit(1)

# createPitList() creates a checklist for taking photos of a teams pit.
def createPitList(api, teams, projectID, checklist, date):
    item = api.items.add('**Take** Pit Photos',
                         project_id=projectID,
                         parent_id=checklist['id'],
                         date_string=date,
                         priority=3)
    for team in teams:
        api.items.add('Pit photo of **{}** {}'.format(team['team_number'], team['nickname']),
                      project_id=projectID,
                      parent_id=item['id'],
                      date_string=date,
                      priority=4)
    api.commit()

# Parse settings config
configString = '[Settings]\n' + open('../settings.conf').read()
configParser = configparser.RawConfigParser()
configParser.read_string(configString)

# Load needed credentials
tbaKey = configParser.get('Settings', 'TBAKey')
todoistToken = configParser.get('Settings', 'TodoistToken')

# Setup Todoist
api = todoist.TodoistAPI(todoistToken)
api.sync()
projectID = getProjectID(api, 'Test')

# Setup the Blue Alliance
tba = tbapy.TBA(tbaKey)
eventKey = '2020ncpem'
event = tba.event(eventKey)
teams = sorted(tba.event_teams(eventKey), key=operator.attrgetter('team_number'))

checklist = api.items.add('{} Photos'.format(event['name']),
                          project_id=projectID,
                          date_string=event['end_date'],
                          priority=2)
api.commit()
createPitList(api, teams, projectID, checklist, event['start_date'])

name = api.state['user']['full_name']
print(name)
