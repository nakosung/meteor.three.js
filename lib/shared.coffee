this.Boxes = new Meteor.Collection('boxes')

Meteor.methods
  'update' : (q,u) ->
    Boxes.update(q,u)