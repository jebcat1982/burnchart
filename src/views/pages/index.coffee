Hero     = require '../hero'
Projects = require '../tables/projects'

projects   = require '../../models/projects'
system     = require '../../models/system'
milestones = require '../../modules/github/milestones'
issues     = require '../../modules/github/issues'
mediator   = require '../../modules/mediator'


module.exports = Ractive.extend

  'name': 'views/pages/index'

  'template': require '../../templates/pages/index'

  'components': { Hero, Projects }

  'data':
    'projects': projects
    'ready': no

  'adapt': [ Ractive.adaptors.Ractive ]

  onrender: ->
    document.title = 'Burnchart: GitHub Burndown Chart as a Service'

    # Quit if we have no projects.
    return @set('ready', yes) unless projects.list.length

    done = do system.async

    async.map projects.data.list, (project, cb) ->
      # Skip if we have milestones already.
      return cb null, project if project.milestones
      # Otherwise fetch them.
      milestones.fetchAll project, (error, list) ->
        # Save the error if project does not exist.
        return cb null, _.extend project, { error } if error
        # Now map in the issues.
        async.map list, (milestone, cb) ->
          issues.fetchAll _.extend(project, { 'milestone': milestone.number }), (err, obj) ->
            cb err, _.extend milestone, { 'issues': obj }
        , (error, list) ->
          delete project.milestone # from fetchAll or do deep clone
          # Save any errors.
          return cb null, _.extend project, { error } if error
          # Otherwise add the milestones.
          cb null, _.extend project, { 'milestones': list }

    , (err, data) =>
      # TODO: Errors are saved on projects. Show them as a notification here too.
      # Save the projects.
      do done
      @set
        'projects.list': data
        'ready': yes