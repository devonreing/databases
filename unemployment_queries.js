/* Question 1
Query to find the number of unique years
*/

db.unemployment.aggregate([
  {
    $group: {
      _id: "$Year"
    }
  },
  {
    $count: "unique_years_count"
  }
])

/* Question 2
Query to find the number of states in the data set
*/
db.unemployment.aggregate([
  {
    $group:
      /**
       * query: The query in MQL.
       */
      {
        _id: "$State"
      }
  },
  {
    $count:
      /**
       * Provide the field name for the count.
       */
      "Number_of_States"
  }
])

// Question 3

db.unemployment.find({Rate : {$lt: 1.0}}).count()

// This query finds the number of counties with a yearly unemployment rate < 1.0% (could have multiple years that count each time for the same county)

/* Question 4
  Query to find all counties with unemployment rate higher than 10%
  */
db.unemployment.aggregate([
  {
    $match:
      /**
       * query: The query in MQL.
       */
      {
        Rate: {
          $gt: 10
        }
      }
  }
])


/*
Question 5
Query to calculate the average unemployment rate across all states.
  */
db.unemployment.aggregate([
  {
    $group:
      /**
       * _id: The id of the group.
       * fieldN: The first field name.
       */
      {
        _id: null,
        avg_rate: {
          $avg: "$Rate"
        }
      }
  }
])

/*
Question 6
Query to find all counties with an unemployment rate between 5% and 8%.
  */
db.unemployment.aggregate([
  {
    $match:
      /**
       * query: The query in MQL.
       */
      {
        Rate: {
          $gt: 5.0,
          $lt: 8.0
        }
      }
  }
])

/*
Question 7
Query to find the state with the highest unemployment rate. Hint. Use { $limit: 1 }
  */
db.unemployment.aggregate([
  {
    $group:
      /**
       * _id: The id of the group.
       * fieldN: The first field name.
       */
      {
        _id: "$State",
        state_avg: {
          $avg: "$Rate"
        }
      }
  },
  {
    $sort:
      /**
       * Provide any number of field/order pairs.
       */
      {
        state_rates: 1
      }
  },
  {
    $limit:
      /**
       * Provide the number of documents to limit.
       */
      1
  }
])

/*
Question 8
Query to count how many counties have an unemployment rate above 5%.
  */

/*
Question 9
Query to calculate the average unemployment rate per state by year.
  */
