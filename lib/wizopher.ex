defmodule Wizopher do
  use Application.Behaviour

  def start(_, options) do
    { :ok, Prairie.open(__MODULE__, options) }
  end

  @host "http://wizardchan.org"
  @boards [
    { :wiz,  "General         " },
    { :v9k,  "Virgin9000      " },
    { :hob,  "Hobbies         " },
    { :meta, "Meta            " },
    { :b,    "Random          " },
    { :stem, "STEM            " },
    { :self, "Self-improvement" } ]

  @faq %B"""
  What do some of the terms on this website mean?

    * KV = kissless virgin; a virgin who has never kissed
    * NEET = a person not in education, employment, or
      training
    * Wizard = a virgin of at least 30 years of age
    * Wizard apprentice = a virgin with the intention or
      inevitability of becoming a wizard
    * Hikki = hikikomori 【引きこもり】; a socially
      withdrawn recluse who rarely leaves his house

  Is there a life chat with fellow users?

    Yes, there is an IRC server at:

    Server: irc.wizardchan.org
    Port: 6667
    Channel: #wiz

  How do I donate?

    You can donate to Wizardchan by sending Bitcoins to
    1PimZM3rayiKzGmePJG6xagcRYiFYg514T.

  How can I contact the admin?

    You can make a thread on /meta/ or contact the admin
    directly by emailing wizardchan@hush.com.
  """

  @rules %B"""
  Wizardchan is a sanctuary for virgins who may be NEET
  or hikikomori to discuss their thoughts, interests,
  and lifestyles. This is an imageboard specifically for
  wizards and wizard apprentices.

  Global

    1. Do not post about your personal sexual
       experiences or allude to the possibility that you
       have any.
    2. Do not post about real life social activities
       or your romantic relationships.
    3. Do not disparage, advise against, or show
       contempt for the celibate, NEET, or reclusive
       lifestyles.
    4. All content should invite constructive,
       thoughtful discussion, not start or feed a
       personal echo chamber.
    6. Do not post, request, or link to any content
       illegal in the United States of America.
    7. Do not create or derail a thread for the sole
       purpose of posting porn or disruptive content.
    8. Try to keep similar topics to one thread;
       duplicates will be locked.
    9. You must be at least 18 years old to use this
       website.
    10. Do not sign your posts with a name, avatar,
        signature, or any variations thereof.
    11. Use the "Spoiler" function when posting
        pornographic content.

  General - /wiz/

    1. Posts may regard any thoughts, ideas, or
       interests, given that they abide by global rules.

  Virgin9000 - /v9k/

    1. Posts related to personal depression are
       contained here.

  Hobbies - /hob/

    1. Posts should relate to the discussion of
       hobbies.

  Meta - /meta/

    1. Posts should relate to Wizardchan, its policies,
       or its community.

  Defitions

    wizard

      A man who has had no sexual experiences before
      the age of thirty. After thirty, this
      distinction can be lost if he has a sexual
      experience.

    wizard apprentice

      A man with the inevitability or desire to become
      a wizard who has had no sexual experiences.

    sexual experience

      Any sexual act between two people. These
      include vaginal sex, oral sex, anal sex, and
      kissing.

    social activity

      An activity that at its core involves
      socializing, like going to a bar, party or club.
      This includes things done together with friends,
      like visiting a cinema. This, however, does not
      include simply having friends, or just making
      contact with another person in real life (e.g. a
      cashier or therapist).

    romantic relationship

      A relationship between two individuals, one of
      whom may want to become intimate with the other.
      This covers both successful ("she was my
      girlfriend") and unsuccessful ("she friendzoned
      me") relationships. Simply having a desire for
      another person (a "crush" or "waifu") is not
      enough to constitute a romantic relationship
      unless contact is made between both parties.

  """

  def handle("/", _) do
    welcome = %B"""
    Welcome to Wizardchan, the image board for wizards by wizards.
    """

    other = [ { :file, "Frequently Asked Questions", "0/faq" },
              { :file, "Rules", "0/rules" } ]

    boards = Enum.map @boards, fn { name, description } ->
      { :directory, "#{description} - /#{name}", "1/#{name}" }
    end

    [format(welcome), other, "", "Here are the available boards.", "", boards] |> List.flatten
  end

  def handle("/faq", :file) do
    { :file, @faq }
  end

  def handle("/rules", :file) do
    { :file, @rules }
  end

  Enum.each @boards, fn { name, _ } ->
    def handle("/" <> unquote(to_string(name)), :directory) do
      catalog_for(unquote(name)) |> Enum.map(fn { path, summary } ->
        [_, id] = Regex.run(%r/(\d+).html/, path)

        [{ :directory, "/#{unquote(name)}/#{id}", "1/#{unquote(name)}/#{id}" }, "", format(summary), ""]
      end) |> List.flatten
    end

    def handle("/" <> unquote(to_string(name)) <> "/" <> id, :directory) do
      thread_for(unquote(name), id) |> Enum.map(fn { post_id, { img, body } } ->
        header = if img do
          { :image, "/#{unquote(name)}/#{post_id}", "I/#{unquote(name)}/#{id}/#{post_id}" }
        else
          { :file, "/#{unquote(name)}/#{post_id}", "0/#{unquote(name)}/#{id}/#{post_id}" }
        end

        [header, "", format(body, unquote(name), id), ""]
      end) |> List.flatten
    end
  end

  def handle(resource, :file) do
    [_, board, thread_id, post_id] = String.split(resource, "/")

    { _, body } = thread_for(board, thread_id)[post_id]

    { :file, unescape(body) }
  end

  def handle(resource, :image) do
    [_, board, thread_id, post_id] = String.split(resource, "/")

    { image, _ } = thread_for(board, thread_id)[post_id]

    { :image, HTTP.get("#{@host}/#{board}/src/#{image}").body }
  end

  defp catalog_for(board) do
    catalog = HTTP.get("#{@host}/#{board}/catalog.html")

    %r{<div class="thread"><a href="(.*?)">.*?</a>.*?</strong><br/>(.*?)</span>}
      |> Regex.scan(catalog.body) |> Enum.map(fn [_, path, summary] ->
        { path, summary }
      end)
  end

  defp thread_for(board, thread_id) do
    thread = HTTP.get("#{@host}/#{board}/res/#{thread_id}.html")

    posts = %r{<p class="intro" id="(\d+)">.*?(?:<a href=".*?/src/(.*?)")?<div class="body">(.*?)</div>}
      |> Regex.scan(thread.body) |> Enum.reduce(HashDict.new, fn [_, id, img, body], dict ->
        if img == "" do
          Dict.put(dict, id, { nil, body })
        else
          [_, img] = Regex.run(%r/(\d+).\w+$/, img)

          Dict.put(dict, id, { img, body })
        end
      end)

    [_, img] = Regex.run(%r{<div id="thread_.*?".*?<a href=".*?/src/(.*?)"}, thread.body)
    posts    = Dict.update(posts, thread_id, fn { _, body } -> { img, body } end)

    Enum.to_list(posts) |> Enum.sort(fn { a, _ }, { b, _ } ->
      binary_to_integer(a) < binary_to_integer(b)
    end)
  end

  defp unescape(body) do
    body |> String.replace(%B{<br/>}, "\r\n")
         |> String.replace(%B{&gt;}, ">")
         |> String.replace(%B{&lt;}, ">")
         |> String.replace(%B{&ndash;}, "–")
         |> String.replace(%B{&hellip;}, "…")
         |> String.replace(%B{<strong>}, "*")
         |> String.replace(%B{</strong>}, "*")
         |> String.replace(%B{<em>}, "_")
         |> String.replace(%B{</em>}, "_")
         |> String.replace(%r{<span class="quote">(.*?)</span>}ms, "\\1")
         |> String.replace(%r{<span class="spoiler">(.*?)</span>}ms, "{ \\1 }")
         |> String.replace(%r{<span class="heading">(.*?)</span>}ms, "## \\1")
         |> String.replace(%r{<a .*?>(.*?)</a>}ms, "\\1")
  end

  defp format(content) do
    unescape(content) |> String.split(%r/\r?\n/) |> Enum.map(&split(&1))
      |> List.flatten
  end

  defp format(content, board, thread_id) do
    unescape(content) |> String.split(%r/\r?\n/) |> Enum.map(fn
      ">>" <> post_id ->
        { :file, ">>#{post_id}", "0/#{board}/#{thread_id}/#{post_id}" }

      line ->
        split(line)
    end) |> List.flatten
  end

  defp split(line) do
    line = line |> String.replace(%r/\s+/, " ")

    if line =~ %r/\s/ do
      split_words(line, 58)
    else
     split_every(line, 58)
    end
  end

  defp split_every(nil, _), do: []
  defp split_every("", _),  do: [""]

  defp split_every(string, length) do
    if String.length(string) < length do
      [string]
    else
      [ String.slice(string, 0, length) |
        String.slice(string, length, String.length(string) - length) |> split_every(length) ]
    end
  end

  def split_words(nil, _), do: []
  def split_words("", _), do: [""]

  def split_words(string, length) do
    string      = string |> String.replace(%r/^\s*/, "")
    line        = String.slice(string, 0, length) |> String.replace(%r/\s*(\w+)?$/, "")
    line_length = String.length(line)

    if line_length == 0 do
      [string]
    else
      [line | split_words(String.slice(string, line_length, String.length(string) - line_length), length)]
    end
  end
end
