1. Fork it ( https://github.com/[my-github-username]/stretchy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Documentation

Our documentation is far from perfect, but if you add new methods to the query chain (ie, anything in `lib/stretchy/clauses`) be sure to document that using the YARD syntax, and also add it to the README.

### Testing

We use rspec for testing, with the latest version of Elasticsearch and Ruby. Until we hit 1.0, no support for older versions of either is planned.

* Use unit tests to ensure basic classes (builders, clauses, etc) behave the way you expect. 
* Test the output of `.to_search` to ensure the JSON being generated for Elasticsearch is what you expect. 
* Write an integration test under `spec/integration` to ensure that using your search terms actually affects the search results.

We run all specs automatically through Solano CI, and specs must pass there before any merge.

### Versioning

The version is only bumped on master after a pull request is merged. We use [Semantic Versioning](http://semver.org/).

* Bug fixes will bump the patch version
* Small new additions will bump the minor version
* Behavior and backwards-incompatible changes will bump the major version

### Style

1. Generally follow the [Github Ruby style guide](https://github.com/styleguide/ruby).
2. Rebase your branch and squash commits into reasonable chunks with good commit messages. No `@wip` or `fix specs` commits. [Here are some guidelines](http://chris.beams.io/posts/git-commit/) for good commit messages.
3. Write specs however they make sense to read. Use `describe` and `it` if your test strings make a sentence, or `context` and `specify` for more specific unit tests.