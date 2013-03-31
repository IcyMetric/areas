Description
=====

This is a simple set of scripts that fetch plists from the central repository and parse them out into per-area files containing some area metadata and job lists.  The intention is so show how these files change over time and to be quick on parsing new plists as they are released.

The repo is broken out into a few directories which are explained bellow.


output
=====

This is what you're probably after.  Within here are directories for each area which contain two files:

* meta.yaml: This contains some data about the area itself, such as level and mastery rewards
* jobs.yaml: Contains the per job level dtail for the area.  This has the drop % and what item along with some basic calculations.

While jobs.yaml does provide a list of what jobs provide what, the real intention of this format was to easily show diffs between data versions.  Yaml was picked because it is a good compromise between being human readable while retaining machine parsability if folks wanted to use this data for their own reasons.

utils
=====

Some of the lamest code I've written.  No really, it is bad.  I encourage you to ignore it.  Only included it so if I ever loose this host I'll have it saved somewhere else.

* doit: A simple shell script that glues the rest of this mess together.  It assumes a bunch of crap, so if you want to reuse this on your own you should check that out.
* parser.rb: This is where the ugly lives.  Seriously I don't normally write stuff this bad.  In an ideal world there would be a plist adapter for datamapper and we'd just use a simple model to map our dependencies.

Of note, the first 3 datasets don't have the same mappings for how things interrelate.  If you were to start this off from scratch you'd want to manually import atleast the 4th oldest dataset.  You should also watch out for the naming convention change mid 2011 that will throw off the sort...

