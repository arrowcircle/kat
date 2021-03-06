require 'minitest/autorun'
require_relative '../../lib/kat/app'

app = Kat::App.new %w(aliens -c movies -o .)
app.kat.go(1).go(app.kat.pages - 1)

describe Kat::App do
  describe 'app' do
    it 'initialises options' do
      app.kat.must_be_instance_of Kat::Search
      app.options.must_be_instance_of Hash
      app.options[:category].must_equal 'movies'
      app.options[:category_given].must_equal true
    end

    it 're-initialises options' do
      k = Kat::App.new %w(aliens)
      k.init_options %w(bible -c books)
      k.options.must_be_instance_of Hash
      k.options[:category].must_equal 'books'
      k.options[:category_given].must_equal true
    end

    it 'creates a validation regex' do
      app.page.must_equal 0
      app.instance_exec do
        @window_width = 80

        prev?.wont_equal true
        next?.must_equal true
        validation_regex.must_equal(/^([inq]|[1-9]|1[0-9]|2[0-5])$/)

        @window_width = 81
        @page = 1

        prev?.must_equal true
        next?.must_equal true
        validation_regex.must_equal(/^([npq]|[1-9]|1[0-9]|2[0-5])$/)

        @page = kat.pages - 1
        n = kat.results[@page].size

        prev?.must_equal true
        next?.wont_equal true
        # Skip the test if there's no results. We really only want to test in
        # ideal network conditions and no results here are an indication that's
        # not the case
        validation_regex.must_equal(
          /^([pq]|[1-#{ [9, n].min }]#{
          "|1[0-#{ [9, n - 10].min }]" if n > 9
          }#{ "|2[0-#{ n - 20 }]" if n > 19 })$/
        ) if n > 0

        @page = 0
      end
    end

    it 'deals with terminal width' do
      app.instance_exec do
        set_window_width
        hide_info?.must_equal(@window_width < 81)
      end
    end

    it 'formats a list of options' do
      app.instance_exec do
        %i(category added platform language).each do |s|
          list = format_lists(s => Kat::Search.selects[s])

          list.must_be_instance_of Array
          list.wont_be_empty

          [0, 2, list.size - 1].each { |i| list[i].must_be_nil }

          str = case s
                when :added    then 'Times'
                when :category then 'Categories'
                else                s.to_s.capitalize << 's'
                end
          list[1].must_equal str

          3.upto(list.size - 2) do |i|
            list[i].must_be_instance_of String
          end unless s == :category

          3.upto(list.size - 2) do |i|
            list[i].must_match(/^\s*([A-Z]+ => )?[a-z0-9-]+/) if list[i]
          end if s == :category
        end
      end
    end

    it 'formats a list of torrents' do
      Kat::Colour.colour = false

      app.instance_exec do
        set_window_width
        list = format_results

        list.must_be_instance_of Array
        list.wont_be_empty

        list.last.must_be_nil

        (2..list.size - 2).each do |i|
          list[i].must_match(/^(\s[1-9]|[12][0-9])\. .*/)
        end
      end
    end

    it 'downloads data from a URL' do
      Kat::Colour.colour = false

      app.instance_exec do
        s = 'foobar'
        result = download(download: 'http://google.com', title: s)
        result.must_equal :done
        File.exist?(File.expand_path "./#{ s }.torrent").must_equal true
        File.delete(File.expand_path "./#{ s }.torrent")
      end
    end

    it 'returns an error message when a download fails' do
      Kat::Colour.colour = false

      app.instance_exec do
        result = download(download: 'http://foo.bar', title: 'foobar')
        result.must_be_instance_of Array
        result.first.must_equal :failed
        result.last.must_match(/^getaddrinfo/)
      end
    end
  end
end
