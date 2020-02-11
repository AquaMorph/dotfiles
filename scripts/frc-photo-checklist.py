#!/usr/bin/env python3

# Program to create a photo checklist of a given frc event.

import configparser
import datetime as dt
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

# createChecklistItem() creates a checklist item of the highest priority.
def createChecklistItem(name, api, projectID, item, date):
    return api.items.add(name,
                         project_id=projectID,
                         parent_id=item['id'],
                         date_string=date,
                         priority=4)

# createPhotoChecklistItem() creates a checklist item that requires a photo.
def createPhotoChecklistItem(name, api, projectID, item, date):
    return createChecklistItem('Take photo of **{}**'.format(name),
                               api, projectID, item, date)

# createPitList() creates a checklist for taking photos of a teams pit.
def createPitList(api, teams, projectID, checklist, date):
    item = api.items.add('**Take** Pit Photos',
                         project_id=projectID,
                         parent_id=checklist['id'],
                         date_string=date,
                         priority=3)
    for team in teams:
        createChecklistItem('Pit photo of **{}** {}'.format(team['team_number'], team['nickname']),
                            api, projectID, item, date)
        
# createGroupsList() creates a checklist of the different groups of volenteers.
def createGroupsList(api, projectID, checklist, date):
    item = api.items.add('Groups',
                         project_id=projectID,
                         parent_id=checklist['id'],
                         date_string=date,
                         priority=3)
    groups = ['Judges', 'Robot Inspectors', 'Referees', 'Safety Inspectors',
              'Field Reset', 'Queuers', 'CSAs', 'VC and Pit Admin']
    for group in groups:
        createPhotoChecklistItem(group, api, projectID, item, date)

# createWinnersList() creates a checklist of the winners of an event.
def createWinnersList(api, projectID, checklist, date):
    item = api.items.add('Winners',
                         project_id=projectID,
                         parent_id=checklist['id'],
                         date_string=date,
                         priority=3)
    groups = ['Chairman\'s award', 'Engineering Inspiration', 'Rookie All-Star', 'Winning Alliance',
              'Winning Team 1', 'Winning Team 2', 'Winning Team 3']
    for group in groups:
        createPhotoChecklistItem(group, api, projectID, item, date)

# createRobotList() creates a checklist for taking photos of a team's robot.
def createRobotList(api, teams, projectID, checklist, date):
    item = api.items.add('**Take** Robot Photos',
                         project_id=projectID,
                         parent_id=checklist['id'],
                         date_string=date,
                         priority=3)
    for team in teams:
        createChecklistItem('Robot photo of **{}** {}'.format(team['team_number'], team['nickname']),
                            api, projectID, item, date)
        
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
setupDay = event['start_date']
day1 = (dt.datetime.strptime(setupDay, '%Y-%m-%d') + dt.timedelta(days=1)).strftime('%Y-%m-%d')
day2 = event['end_date']
teams = sorted(tba.event_teams(eventKey), key=operator.attrgetter('team_number'))

# Create checklist
checklist = api.items.add('{} Photos'.format(event['name']),
                          project_id=projectID,
                          date_string=day2,
                          priority=2)

# Setup
createPitList(api, teams, projectID, checklist, setupDay)
createChecklistItem('**Schedule** Judges photo', api, projectID, checklist, setupDay)
createChecklistItem('**Schedule** Inspectors photo', api, projectID, checklist, setupDay)
createChecklistItem('**Schedule** Seniors photo', api, projectID, checklist, setupDay)
createGroupsList(api, projectID, checklist, setupDay)
# Day 1
createPhotoChecklistItem('Guest Speakers', api, projectID, checklist, day1)
createRobotList(api, teams, projectID, checklist, day1)
# Day 2
createPhotoChecklistItem('Guest Speakers', api, projectID, checklist, day2)
createPhotoChecklistItem('Mentors after parade', api, projectID, checklist, day2)
createPhotoChecklistItem('Seniors', api, projectID, checklist, day2)
createPhotoChecklistItem('Alliances Representatives', api, projectID, checklist, day2)
createWinnersList(api, projectID, checklist, day2)
createChecklistItem('**Email** guest speakers and winners photos', api, projectID, checklist, day2)
api.commit()
