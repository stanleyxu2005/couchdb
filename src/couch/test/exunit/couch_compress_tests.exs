defmodule Couch.Test.CouchCompress do
  use Couch.Test.ExUnit.Case
  alias Couch.Test.Utils

  alias Couch.Test.Setup

  alias Couch.Test.Setup.Step

  import Utils

  @term {[{:a, 1}, {:b, 2}, {:c, 3}, {:d, 4}, {:e, 5}]}

  @none <<131, 104, 1, 108, 0, 0, 0, 5, 104, 2, 100, 0, 1, 97, 97, 1, 104, 2, 100, 0, 1,
          98, 97, 2, 104, 2, 100, 0, 1, 99, 97, 3, 104, 2, 100, 0, 1, 100, 97, 4, 104, 2,
          100, 0, 1, 101, 97, 5, 106>>

  @deflate <<131, 80, 0, 0, 0, 48, 120, 218, 203, 96, 204, 97, 96, 96, 96, 205, 96, 74,
             97, 96, 76, 76, 100, 4, 211, 73, 137, 76, 96, 58, 57, 145, 25, 76, 167, 36,
             178, 128, 233, 212, 68, 214, 44, 0, 212, 169, 9, 51>>

  @snappy <<1, 49, 64, 131, 104, 1, 108, 0, 0, 0, 5, 104, 2, 100, 0, 1, 97, 97, 1, 104, 1,
            8, 8, 98, 97, 2, 5, 8, 8, 99, 97, 3, 5, 8, 44, 100, 97, 4, 104, 2, 100, 0, 1,
            101, 97, 5, 106>>

  @corrupt <<2, 12, 85, 06>>

  describe "CouchDB Compression" do
    test "compress" do
      assert @none === :couch_compress.compress(@term, :none)
      assert @deflate === :couch_compress.compress(@term, {:deflate, 9})
      assert @snappy === :couch_compress.compress(@term, :snappy)
    end

    test "decompress" do
      assert @term === :couch_compress.decompress(@none)
      assert @term === :couch_compress.decompress(@deflate)
      assert @term === :couch_compress.decompress(@snappy)
      assert catch_error(:couch_compress.decompress(@corrupt)) == :invalid_compression
    end

    test "recompress" do
      assert @deflate === :couch_compress.compress(@none, {:deflate, 9})
      assert @snappy === :couch_compress.compress(@none, :snappy)
      assert @none === :couch_compress.compress(@deflate, :none)
      assert @snappy === :couch_compress.compress(@deflate, :snappy)
      assert @none === :couch_compress.compress(@snappy, :none)
      assert @deflate === :couch_compress.compress(@snappy, {:deflate, 9})
    end

    test "is compressed" do
      assert :couch_compress.is_compressed(@none, :none)
      assert :couch_compress.is_compressed(@deflate, {:deflate, 9})
      assert :couch_compress.is_compressed(@snappy, :snappy)
      refute :couch_compress.is_compressed(@none, {:deflate, 0})
      refute :couch_compress.is_compressed(@none, {:deflate, 9})
      refute :couch_compress.is_compressed(@none, :snappy)
      refute :couch_compress.is_compressed(@deflate, :none)
      refute :couch_compress.is_compressed(@deflate, :snappy)
      refute :couch_compress.is_compressed(@snappy, :none)
      refute :couch_compress.is_compressed(@snappy, {:deflate, 9})

      assert catch_error(:couch_compress.is_compressed(@corrupt, :none)) ==
               :invalid_compression

      assert catch_error(:couch_compress.is_compressed(@corrupt, {:deflate, 9})) ==
               :invalid_compression

      assert catch_error(:couch_compress.is_compressed(@corrupt, :snappy)) ==
               :invalid_compression
    end

    test "uncompressed size" do
      assert :couch_compress.uncompressed_size(@none) === 49
      assert :couch_compress.uncompressed_size(@deflate) === 49
      assert :couch_compress.uncompressed_size(@snappy) === 49

      assert :couch_compress.uncompressed_size(
               :couch_compress.compress(:x, {:deflate, 9})
             ) === 5

      assert catch_error(:couch_compress.uncompressed_size(@corrupt)) ==
               :invalid_compression
    end
  end
end
