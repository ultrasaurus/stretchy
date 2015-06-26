[![](https://ci.solanolabs.com:443/Hired/stretchy/badges/branches/master?badge_token=062c34bcb84d3502662722bf76a8b4ec9fa073d9)](https://ci.solanolabs.com:443/Hired/stretchy/suites/246591)

# Stretchy

Stretchy is a query builder for [Elasticsearch](https://www.elastic.co/products/elasticsearch). It helps you quickly construct the JSON to send to Elastic, which can get [rather complicated](http://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html). 

Stretchy is modeled after ActiveRecord's interface and architecture - query objects are immutable and chainable, which makes quickly building the right query and caching the results easy.

Stretchy is *not*:

1. an integration with ActiveModel to help you index your data
2. a way to manage Elasticsearch configuration
3. a general-purpose Elasticsearch API client

The first two are very application-specific. For any non-trivial app, the level of customization necessary will have you writing almost everything yourself. The last one is better handled by the [elasticsearch gem](http://www.rubydoc.info/gems/elasticsearch-api/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stretchy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install stretchy

## Usage

Stretchy is still in early development, so it does not yet support the full feature set of the [Elasticsearch API](http://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html). It does support fairly basic queries in an ActiveRecord-ish style.

### Documentation

See [the Stretchy docs on rubydocs](http://www.rubydoc.info/gems/stretchy) for fairly detailed documentation on the API. Specifically, you'll probably want the docs for [Stretchy Clauses](http://www.rubydoc.info/gems/stretchy/Stretchy/Clauses/Base), which make up the basis of the query builder.

### Configuration

```ruby
Stretchy.configure do |c|
  c.index_name = 'my_index'                       # REQUIRED
  c.client     = $my_client                       # ignore below, use a custom client
  c.url        = 'https://user:pw@my.elastic.url' # default is ENV['ELASTICSEARCH_URL']
  c.adapter    = :patron                          # default is :excon

  c.logger     = Logger.new(STDOUT)               # passed to elasticsearch-api gem
                                                  # Stretchy will also log, with the params
                                                  # specified below
  c.log_level  = :debug                           # default is :silence
  c.log_color  = :green                           # default is :blue 
end
```

### Base

```ruby
query = Stretchy.query(type: 'model_name')
```

From here, you can chain the following query methods:

### Fulltext

```ruby
query = query.fulltext('Generic user-input phrase')
             .fulltext(author: 'John Romero')
```

Performs a query for the given string, either anywhere in the document or in specific fields. At least one of the terms must match, and the closer a document is to having the exact phrase, the higher its' score. See the Elasticsearch guide's [article on proximity scoring](https://www.elastic.co/guide/en/elasticsearch/guide/current/proximity-relevance.html) for more info on how this works.

### Match

```ruby
query = query.match('welcome to my web site')
             .match(title: 'welcome to my web site')
             .match(image: 'loading construction flash', operator: 'or')
```

Performs a match query for the given string. If given a hash, it will use a match query on the specified fields, otherwise it will default to `'_all'`. By default, a match query searches for any of the analyzed terms in the document, and scores them using Lucene's [practical scoring formula](https://www.elastic.co/guide/en/elasticsearch/guide/current/practical-scoring-function.html), which combines TF/IDF, the vector space model, and a few other niceties.

### More Like

```ruby
query = query.more_like(ids: [1, 2, 3])
             .more_like(docs: other_search.results)
             .more_like(like_text: 'puppies and kittens are great', fields: :about_me)
```

Finds documents similar to a list of input documents. You must pass in one of the `:ids`, `:docs` or `:like_text` parameters, but everything else is optional. This method accepts any of the params available in the [Elasticsearch more_like_this query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-mlt-query.html). It can also be chained with `.not` and `.should`.

### Where

```ruby
query = query.where(
  name: 'alice',
  email: [
    'alice@company.com',
    'beatrice.christine@other_company.com'
  ],
  commit_count: 27..33,
  is_robot: nil
)
```

Allows passing a hash of matchable options similar to ActiveRecord's `where` method. To be returned, the document must match each of the parameters. If you pass an array of parameters for a field, the document must match at least one of those parameters.

#### Gotcha

If you pass a string or symbol for a field, it will be converted to a [Match Query](http://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query.html) for the specified field. Since Elastic analyzes terms by default, string or symbol terms will be looked for by an analyzed query.

To query for _exact_ matches against strings or symbols with underscores and punctuation intact, use the `.where.terms` clause.

### Terms

```ruby
query = query.where.terms(
          email: 'happy.developer@company.com',
          status: :awesome
        )
```

Sometimes you store values with punctuation, underscores, or other characters Elasticsearch would normally split into separate terms. If you want to query all comments that match a specific email address, you need to make sure that Elasticsearch doesn't analyze the query terms you send it before running the query. This clause allows you to do that.

### Range

```ruby
query = query.range(:rating, min: 3, max: 5)
             .range(:released, min: Time.now - 60*60*24*100)
             .range(:quantity, max: 100, exclusive: true)
```

Only documents with the specified field, and within the specified range match. You can also pass in dates and times as ranges. While you could pass a normal ruby `Range` object to `.where`, this allows you to specify only a minimum or only a maximum. Range filters are inclusive by default, but you can also pass `:exclusive`, `:exclusive_min`, or `:exclusive_max`.

### Geo Distance

```ruby
query = query.geo(field: 'coords', distance: '20mi', lat: 35.0117, lng: 135.7683)
```

Filters for documents where the specified `geo_point` field is within the given range.

#### Gotcha

The field must be mapped as a `geo_point` field. See [Elasticsearch types](http://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-geo-point-type.html) for more info.

### Not

```ruby
query = query.where.not(rating: 0)
             .match.not('angry')
             .where.not.geo(field: 'coords', distance: '20mi', lat: 35.0117, lng: 135.7683)
```

Called after `where` or `match` will let you apply inverted filters. Any documents that match those filters will be excluded.

### Should

```ruby
query = query.should(name: 'Sarah', awesomeness: 1000).should.not(awesomeness: 0)
```

Should filters work similarly to `.where`. Documents that do not match are still returned, but they have a lower relevancy score and will appear after documents that do match in the results. See Elastic's documentation for [BoolQuery](http://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html) and [BoolFilter](http://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-filter.html) for more info.

### Boost

```ruby
query = query.boost.where(category: 3, weight: 100)
             .boost.range(:awesomeness, min: 10, weight: 10)
             .boost.match.not('sucks')
```

Boosts use a [Function Score Query](http://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html) with filters to allow you to affect the score for the document. Each condition will be applied as a filter with an optional weight.


### Near

```ruby
query = query.boost.near(field: :published_at, origin: Time.now, scale: '5d')
             .boost.near(field: :coords, lat: 35.0117, lng: 135.7683, scale: '10mi', decay: 0.33, weight: 1000)
```

Boosts a document by how close a given field is to a given `:origin` . Accepts dates, times, numbers, and geographical points. Unlike `.where.range` or `.boost.geo`, `.boost.near` is not a binary operation. All documents get a score for that field, which decays the further it is away from the origin point. 

The `:scale` param determines how quickly the value falls off. In the example above, if a document's `:coords` field is 10 miles away from the starting point, its score is about 1/3 that of a document at the origin point.

See the [Function Score Query](http://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html) section on Decay Functions for more info.

### Field

```ruby
query = query.boost.field(:popularity)
             .boost.field(:timestamp, factor: 0.5, modifier: :sqrt)
             .boost.field(:votes, :bookmarks, :comments)
```

Boosts a document by a numeric value contained in the specified fields. You can also specify a `factor` (an amount to multiply the field value by) and a `modifier` (a function for normalizing values).

See the [Boosting By Popularity Guide](https://www.elastic.co/guide/en/elasticsearch/guide/current/boosting-by-popularity.html) and the [Field Value Factor documentation](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#_field_value_factor) for more info.

### Random

```ruby
query = query.boost.random(user.id, 50)
```

Gives each document a randomized boost with a given seed and optional weight. This allows you to show slightly different result sets to different users, but show the same result set to that user every time.

### Limit and Offset

```ruby
query = query.limit(20).offset(1000)
```

Works the same way as ActiveRecord's limit and offset methods - analogous to Elasticsearch's `from` and `size` parameters.

### Response

```ruby
query.response
```

Executes the query, returns the raw JSON response from Elasticsearch and caches it. Use this to get at search API data not in the source documents.

### Results

```ruby
query.results
```

Executes the query and provides the parsed json for each hit returned by Elasticsearch, along with `_index`, `_type`, `_id`, and `_score` fields.

### Ids

```ruby
query.ids
```

Provides only the ids for each hit. If your document ids are numeric (as is the case for many ActiveRecord integrations), they will be converted to integers.

### Total

```ruby
query.total
```

Returns the total number of matches returned by the query - not just the current page. Makes plugging into [Kaminari](https://github.com/amatsuda/kaminari) a snap.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing
