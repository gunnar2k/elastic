defmodule Elastic.User.NameTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Elastic.User.Name

  @valid_non_infix_chars 0x21..0x7E

  def valid_username_gen do
    gen all(
          text <- string(0x20..0x7E, min_length: 1, max_length: 341),
          prefix <- string(@valid_non_infix_chars, min_length: 1, max_length: 341),
          postfix <- string(@valid_non_infix_chars, min_length: 1, max_length: 341)
        ) do
      prefix <> text <> postfix
    end
  end

  describe "is_valid_username?/1" do
    test "given empty string, returns false" do
      assert Name.is_valid?("") == false
    end

    property "given a short, valid sequence, returns true" do
      check all(username <- string(@valid_non_infix_chars, min_length: 1, max_length: 3)) do
        assert Name.is_valid?(username) == true
      end
    end

    property "given a string with leading spaces, returns false" do
      check all(
              text <- string(@valid_non_infix_chars, min_length: 1, max_length: 1024),
              prefix <- string(0x20..0x20, min_length: 1, max_length: 20)
            ) do
        username = prefix <> text
        assert Name.is_valid?(username) == false
      end
    end

    property "given a string with trailing spaces, returns false" do
      check all(
              text <- string(@valid_non_infix_chars, min_length: 1, max_length: 1024),
              postfix <- string(0x20..0x20, min_length: 1, max_length: 20)
            ) do
        username = text <> postfix
        assert Name.is_valid?(username) == false
      end
    end

    property "given a string with leading and trailing spaces, returns false" do
      check all(
              text <- string(@valid_non_infix_chars, min_length: 1, max_length: 1024),
              prefix <- string(0x20..0x20, min_length: 1, max_length: 20),
              postfix <- string(0x20..0x20, min_length: 1, max_length: 20)
            ) do
        username = prefix <> text <> postfix
        assert Name.is_valid?(username) == false
      end
    end

    property "given a string with length > 1024 bytes, returns false" do
      check all(username <- string(@valid_non_infix_chars, min_length: 1025, max_length: 10_000)) do
        assert Name.is_valid?(username) == false
      end
    end

    property "given a valid name, returns true" do
      check all(username <- valid_username_gen()) do
        assert Name.is_valid?(username) == true
      end
    end
  end
end
