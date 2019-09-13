import { Aggregator, Request, Source, Tally, Types } from "witnet-requests"
const { REDUCERS } = Types

const web365 = new Source("https://webws.365scores.com/web/game/?gameId=2088066")
  .parseJSON().asMap()
  .get("game").asMap()
  .get("awayCompetitor").asMap()
  .get("score").asFloat()
  .round()

const sofascore = new Source("https://www.sofascore.com/event/8397714/json")
  .parseJSON().asMap()
  .get("event").asMap()
  .get("awayScore").asMap()
  .get("current").asFloat()
  .round()

const aggregator = new Aggregator([sofascore, web365])
  // .flatten()
  .reduce(REDUCERS.mode)
  // .get(0)

const tally = new Tally(aggregator)
  // .flatten()
  .reduce(REDUCERS.mode)
  // .get(0)

const request = new Request()
  .addSource(sofascore)
  .addSource(web365)
  .setAggregator(aggregator)
  .setTally(tally)
  .setFees(10, 1, 1, 1)
  .setQuorum(1, 1)
  // .schedule(1669852800)

export { request as default }
