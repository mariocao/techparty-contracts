import { Aggregator, Request, Source, Tally, Types } from "witnet-requests"
const { REDUCERS } = Types

const web365 = new Source("https://webws.365scores.com/web/game/?gameId=2049655")
  .parseJSON().asMap()
  .get("game").asMap()
  .get("awayCompetitor").asMap()
  .get("score").asFloat()
  .round()

const sofascore = new Source("https://www.sofascore.com/event/8339932/json")
  .parseJSON().asMap()
  .get("event").asMap()
  .get("awayScore").asMap()
  .get("current").asFloat()
  .round()
  
const marca = new Source("https://api.unidadeditorial.es/sports/v1/events/preset/1_99a16e5b?date=2019-09-11")
  .parseJSON().asMap()
  .get("data").asArray()
  .get(0).asMap()
  .get("score").asMap()
  .get("homeTeam").asMap()
  .get("totalScore").asFloat()
  .round()

  const apifootball = new Source("https://apiv2.apifootball.com/?action=get_events&from=2019-09-11&to=2019-09-11&match_id=295885&APIkey=01560c58db0e4574a1c180499cfdf9ab001b1de4b1b3b879d7df5f99e6ce32bc")
  .parseJSON().asArray()
  .get(0).asMap()
  .get("match_awayteam_score").asFloat()
  .round()

const aggregator = new Aggregator([sofascore, web365, marca, apifootball])
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
  .addSource(marca)
  .addSource(apifootball)
  .setAggregator(aggregator)
  .setTally(tally)
  // .schedule(1669852800)

export { request as default }
