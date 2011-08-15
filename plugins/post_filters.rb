require 'pp'
module Jekyll
  class PostFilter < Plugin
    #Called before post is sent to the converter. Allows
    #you to modify the post object before the converter
    #does it's thing
    def pre_render(post)
    end

    #Called after the post is rendered with the converter.
    #Use the post object to modify it's contents before the
    #post is inserted into the template.
    def post_render(post)
    end

    #Called after the post is written to the disk.
    #Use the post object to read it's contents to do something
    #after the post is safely written.
    def post_write(post)
    end
  end

  class Site
    attr_accessor :post_filters

    def load_post_filters
      self.post_filters = Jekyll::PostFilter.subclasses.select do |c|
        !self.safe || c.safe
      end.map do |c|
        c.new(self.config)
      end
    end
  end

  class Post
    alias_method :old_write, :write

    def write(dest)
      old_write(dest)

      if self.site.post_filters
        self.site.post_filters.each do |filter|
          filter.post_write(self)
        end
      end
    end

    def pre_render
      if self.site.post_filters
        self.site.post_filters.each do |filter|
          filter.pre_render(self)
        end
      else
        self.site.load_post_filters
      end
    end

    def post_render
      if self.site.post_filters
        self.site.post_filters.each do |filter|
          filter.post_render(self)
        end
      end
    end

    def full_url
      self.site.config['url'] + self.url
    end
  end

  module Convertible
    alias_method :old_transform, :transform

    def transform
      old_transform
      post_render if respond_to?(:post_render)
    end

    alias_method :old_do_layout, :do_layout

    def do_layout(payload, layouts)
      pre_render if respond_to?(:pre_render)
      old_do_layout(payload, layouts)
    end
  end
end
