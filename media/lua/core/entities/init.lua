local log = require("core.logger")

log.log(log.DEBUG, ":::: State variables.")
require("core.entities.svars")

log.log(log.DEBUG, ":::: Entities.")
require("core.entities.ents")

log.log(log.DEBUG, ":::: Entities: basic set.")
require("core.entities.ents_basic")
