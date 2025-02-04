import BaseModel       from '@/shared/record_store/base_model'
import AppConfig       from '@/shared/services/app_config'
import HasDocuments    from '@/shared/mixins/has_documents'
import HasTranslations from '@/shared/mixins/has_translations'
import {capitalize, map, last, invokeMap} from 'lodash'

export default class CommentModel extends BaseModel
  @singular: 'comment'
  @plural: 'comments'
  @indices: ['discussionId', 'authorId']

  afterConstruction: ->
    HasDocuments.apply @
    HasTranslations.apply @

  defaultValues: ->
    usesMarkdown: true
    discussionId: null
    files: []
    imageFiles: []
    attachments: []
    linkPreviews: []
    body: '<p></p>'
    bodyFormat: 'html'
    mentionedUsernames: []

  relationships: ->
    @belongsTo 'author', from: 'users'
    @belongsTo 'discussion'
    @belongsTo 'parent', from: 'comments', by: 'parentId'
    # @hasMany  'versions', sortBy: 'createdAt'

  createdEvent: ->
    @recordStore.events.find(kind: "new_comment", eventableId: @id)[0]

  reactions: ->
    @recordStore.reactions.find
      reactableId: @id
      reactableType: capitalize(@constructor.singular)

  group: ->
    @discussion().group()

  memberIds: ->
    @discussion().memberIds()

  # isMostRecent: ->
  #   last(@discussion().comments()) == @
  participantIds: ->
    @discussion().participantIds()

  isReply: ->
    @parentId?

  isBlank: ->
    @body == '' or @body == null or @body == '<p></p>'

  hasDescription: ->
    !!@body

  parent: ->
    @recordStore.comments.find(@parentId)

  reactors: ->
    @recordStore.users.find(map(@reactions(), 'userId'))

  authorName: ->
    @author().nameWithTitle(@discussion().group()) if @author()

  authorUsername: ->
    @author().username

  authorAvatar: ->
    @author().avatarOrInitials()

  beforeDestroy: ->
    invokeMap @recordStore.events.find(kind: 'new_comment', eventableId: @id), 'remove'
