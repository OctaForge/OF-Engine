var log = require("core.logger")

log.log(log.DEBUG, ":::: Frame handling.")
require("core.events.frame")

log.log(log.DEBUG, ":::: Signal system.")
require("core.events.signal")

log.log(log.DEBUG, ":::: Action system.")
require("core.events.actions")

log.log(log.DEBUG, ":::: World events.")
require("core.events.world")

log.log(log.DEBUG, ":::: Input events.")
require("core.events.input")
