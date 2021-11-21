#lang at-exp racket/base

;; Unit tests

(require "main.rkt"
         gregor
         racket/format
         rackunit)

(define site-id (mint-tag-uri "example.com" "2007" "blog"))

;; Updated time occurring before published time results in exception
(check-exn
 exn:fail:contract?
 (λ () (feed-item (append-specific site-id "one")
                "https://example.com/blog/one.html"
                "Kate's First Post"
                (person "Kate Poster" "kate@example.com")
                (infer-moment "2007-03-17")
                (infer-moment "2007-03-16")
                `(div (p "Welcome to my blog.") (ul (li "& ' < > © ℗ ™")))
                (enclosure "gopher://umn.edu/greeting.m4a" "audio/x-m4a" 1234))))

(check-exn exn:fail:contract? (λ () (feed site-id "not a url" "Title" (list e1))))

;; Check complete feed output for both Atom and RSS
(define e1
  (parameterize ([current-timezone 0])
    (feed-item (append-specific site-id "one")
                "https://example.com/blog/one.html"
                "Kate's First Post"
                (person "Kate Poster" "kate@example.com")
                (infer-moment "2007-03-17")
                (infer-moment "2007-03-17")
                `(div (p "Welcome to my blog.") (ul (li "& ' < > © ℗ ™")))
                (enclosure "gopher://umn.edu/greeting.m4a" "audio/x-m4a" 1234))))

(define f1 (feed site-id "https://example.com/" "Kate Poster Posts" (list e1)))

(define expect-feed-atom @~a{
<?xml version="1.0" encoding="UTF-8"?>

<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title type="text">Kate Poster Posts</title>
  <link rel="self" href="https://example.com/feed.atom" />
  <link rel="alternate" href="https://example.com/" />
  <updated>2007-03-17T00:00:00Z</updated>
  <id>tag:example.com,2007:blog</id>
  <entry>
    <title type="text">Kate's First Post</title>
    <link rel="alternate" href="https://example.com/blog/one.html" />
    <updated>2007-03-17T00:00:00Z</updated>
    <published>2007-03-17T00:00:00Z</published>
    <link rel="enclosure" type="audio/x-m4a" length="1234" href="gopher://umn.edu/greeting.m4a" />
    <author>
      <name>Kate Poster</name>
      <email>kate@"@"example.com</email>
    </author>
    <id>tag:example.com,2007:blog.one</id>
    <content type="html">&lt;div&gt;&lt;p&gt;Welcome to my blog.&lt;/p&gt;&lt;ul&gt;&lt;li&gt;&amp;amp; ' &amp;lt; &amp;gt; © ℗ ™&lt;/li&gt;&lt;/ul&gt;&lt;/div&gt;</content>
  </entry>
</feed>})

(define expect-feed-rss @~a{
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>Kate Poster Posts</title>
    <atom:link rel="self" href="https://example.com/feed.rss" type="application/rss+xml" />
    <link>https://example.com/</link>
    <pubDate>Sat, 17 Mar 2007 00:00:00 +0000</pubDate>
    <lastBuildDate>Sat, 17 Mar 2007 00:00:00 +0000</lastBuildDate>
    <description>Kate Poster Posts</description>
    <language>en</language>
    <item>
      <title>Kate's First Post</title>
      <link>https://example.com/blog/one.html</link>
      <pubDate>Sat, 17 Mar 2007 00:00:00 +0000</pubDate>
      <enclosure url="gopher://umn.edu/greeting.m4a" length="1234" type="audio/x-m4a" />
      <author>kate@"@"example.com (Kate Poster)</author>
      <guid isPermaLink="false">tag:example.com,2007:blog.one</guid>
      <description>&lt;div&gt;&lt;p&gt;Welcome to my blog.&lt;/p&gt;&lt;ul&gt;&lt;li&gt;&amp;amp; ' &amp;lt; &amp;gt; © ℗ ™&lt;/li&gt;&lt;/ul&gt;&lt;/div&gt;</description>
    </item>
  </channel>
</rss>})

(parameterize ([include-generator? #f]
               [feed-language 'en])
  (check-equal? (express-xml f1 'atom "https://example.com/feed.atom") expect-feed-atom)
  (check-equal? (express-xml f1 'rss "https://example.com/feed.rss") expect-feed-rss))

;; Check podcast episode output
(define test-ep1
  (parameterize ([current-timezone 0])
  (episode (append-specific site-id "ep1")
           "http://example.com/ep1"
           "Kate Speaks"
           (person "Kate Poster" "kate@example.com")
           (infer-moment "2021-10-31")
           (infer-moment "2021-10-31")
           '(article (p "Welcome to the show"))
          (enclosure "http://example.com/ep1.m4a" "audio/x-m4a" 1234)
           )))

(define expect-ep1 @~a{
<item>
  <title>Kate Speaks</title>
  <link>http://example.com/ep1</link>
  <pubDate>Sun, 31 Oct 2021 00:00:00 +0000</pubDate>
  <enclosure url="http://example.com/ep1.m4a" length="1234" type="audio/x-m4a" />
  <author>kate@"@"example.com (Kate Poster)</author>
  <guid isPermaLink="false">tag:example.com,2007:blog.ep1</guid>
  <description>&lt;article&gt;&lt;p&gt;Welcome to the show&lt;/p&gt;&lt;/article&gt;</description>
</item>
})

(check-equal? (express-xml test-ep1 'rss) expect-ep1 )
(check-equal? (express-xml test-ep1 'atom) expect-ep1) ; ignores dialect
                                        ;
(define test-ep2
  (parameterize ([current-timezone 0])
  (episode (append-specific site-id "ep2")
           "http://example.com/ep2"
           "Kate Speaks"
           (person "Kate Poster" "kate@example.com")
           (infer-moment "2021-10-31")
           (infer-moment "2021-10-31")
           `(article (p "Welcome to another show"))
          (enclosure "http://example.com/ep2.m4a" "audio/x-m4a" 1234)
          #:duration 300
          #:image-url "http://example.com/ep1-cover.png"
          #:explicit? (even? 7)
          #:episode-num 2
          #:season-num 1
          #:type 'full
          #:block? (< 3 17 99)
           )))

(define expect-ep2 @~a{
<item>
  <title>Kate Speaks</title>
  <link>http://example.com/ep2</link>
  <pubDate>Sun, 31 Oct 2021 00:00:00 +0000</pubDate>
  <enclosure url="http://example.com/ep2.m4a" length="1234" type="audio/x-m4a" />
  <itunes:episodeType>full</itunes:episodeType>
  <author>kate@"@"example.com (Kate Poster)</author>
  <guid isPermaLink="false">tag:example.com,2007:blog.ep2</guid>
  <description>&lt;article&gt;&lt;p&gt;Welcome to another show&lt;/p&gt;&lt;/article&gt;</description>
  <itunes:duration>300</itunes:duration>
  <itunes:explicit>false</itunes:explicit>
  <itunes:image href="http://example.com/ep1-cover.png" />
  <itunes:episode>2</itunes:episode>
  <itunes:season>1</itunes:season>
  <itunes:block>Yes</itunes:block>
</item>
})

(check-equal? (express-xml test-ep2 'rss) expect-ep2 )
(check-equal? (express-xml test-ep2 'atom) expect-ep2) ; ignores dialect

;; 
(define test-podcast
  (podcast site-id
           "https://example.com"
           "Kate Does a Podcast"
           (list test-ep1)
           (list "Leisure" "Animation & Manga")
           "https://example.com/cover-art.jpg"
           (person "Kate Poster" "kate@example.com")
           #:explicit? #t))

(define expect-podcast @~a{
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
  <channel>
    <title>Kate Does a Podcast</title>
    <atom:link rel="self" href="https://example.com/podcast.rss" type="application/rss+xml" />
    <link>https://example.com</link>
    <pubDate>Sun, 31 Oct 2021 00:00:00 +0000</pubDate>
    <lastBuildDate>Sun, 31 Oct 2021 00:00:00 +0000</lastBuildDate>
    <description>Kate Does a Podcast</description>
    <language>en</language>
    <itunes:owner>
      <itunes:name>Kate Poster</itunes:name>
      <itunes:email>kate@"@"example.com</itunes:email>
    </itunes:owner>
    <itunes:image href="https://example.com/cover-art.jpg" />
    <itunes:category text="Leisure">
      <itunes:category text="Animation &amp; Manga" />
    </itunes:category>
    <itunes:explicit>yes</itunes:explicit>
    <item>
      <title>Kate Speaks</title>
      <link>http://example.com/ep1</link>
      <pubDate>Sun, 31 Oct 2021 00:00:00 +0000</pubDate>
      <enclosure url="http://example.com/ep1.m4a" length="1234" type="audio/x-m4a" />
      <author>kate@"@"example.com (Kate Poster)</author>
      <guid isPermaLink="false">tag:example.com,2007:blog.ep1</guid>
      <description>&lt;article&gt;&lt;p&gt;Welcome to the show&lt;/p&gt;&lt;/article&gt;</description>
    </item>
  </channel>
</rss>
})

(parameterize ([include-generator? #f]
               [feed-language 'en])
  (check-equal? (express-xml test-podcast 'rss "https://example.com/podcast.rss") expect-podcast))