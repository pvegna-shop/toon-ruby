# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Toon.decode' do
  describe 'primitives' do
    it 'decodes safe unquoted strings' do
      expect(Toon.decode('hello')).to eq('hello')
      expect(Toon.decode('Ada_99')).to eq('Ada_99')
    end

    it 'decodes quoted strings and unescapes control characters' do
      expect(Toon.decode('""')).to eq('')
      expect(Toon.decode('"line1\\nline2"')).to eq("line1\nline2")
      expect(Toon.decode('"tab\\there"')).to eq("tab\there")
      expect(Toon.decode('"return\\rcarriage"')).to eq("return\rcarriage")
      expect(Toon.decode('"C:\\\\Users\\\\path"')).to eq('C:\\Users\\path')
      expect(Toon.decode('"say \\"hello\\""')).to eq('say "hello"')
    end

    it 'decodes unicode and emoji' do
      expect(Toon.decode('café')).to eq('café')
      expect(Toon.decode('你好')).to eq('你好')
      expect(Toon.decode('🚀')).to eq('🚀')
      expect(Toon.decode('hello 👋 world')).to eq('hello 👋 world')
    end

    it 'decodes numbers, booleans and null' do
      expect(Toon.decode('42')).to eq(42)
      expect(Toon.decode('3.14')).to eq(3.14)
      expect(Toon.decode('-7')).to eq(-7)
      expect(Toon.decode('true')).to eq(true)
      expect(Toon.decode('false')).to eq(false)
      expect(Toon.decode('null')).to eq(nil)
    end

    it 'treats unquoted invalid numeric formats as strings' do
      expect(Toon.decode('05')).to eq('05')
      expect(Toon.decode('007')).to eq('007')
      expect(Toon.decode('0123')).to eq('0123')
      expect(Toon.decode('a: 05')).to eq({ 'a' => '05' })
      expect(Toon.decode('nums[3]: 05,007,0123')).to eq({ 'nums' => ['05', '007', '0123'] })
    end

    it 'respects ambiguity quoting (quoted primitives remain strings)' do
      expect(Toon.decode('"true"')).to eq('true')
      expect(Toon.decode('"false"')).to eq('false')
      expect(Toon.decode('"null"')).to eq('null')
      expect(Toon.decode('"42"')).to eq('42')
      expect(Toon.decode('"-3.14"')).to eq('-3.14')
      expect(Toon.decode('"1e-6"')).to eq('1e-6')
      expect(Toon.decode('"05"')).to eq('05')
    end
  end

  describe 'objects (simple)' do
    it 'parses objects with primitive values' do
      toon = "id: 123\nname: Ada\nactive: true"
      expect(Toon.decode(toon)).to eq({ 'id' => 123, 'name' => 'Ada', 'active' => true })
    end

    it 'parses null values in objects' do
      toon = "id: 123\nvalue: null"
      expect(Toon.decode(toon)).to eq({ 'id' => 123, 'value' => nil })
    end

    it 'parses empty nested object header' do
      expect(Toon.decode('user:')).to eq({ 'user' => {} })
    end

    it 'parses quoted object values with special characters and escapes' do
      expect(Toon.decode('note: "a:b"')).to eq({ 'note' => 'a:b' })
      expect(Toon.decode('note: "a,b"')).to eq({ 'note' => 'a,b' })
      expect(Toon.decode('text: "line1\\nline2"')).to eq({ 'text' => "line1\nline2" })
      expect(Toon.decode('text: "say \\"hello\\""')).to eq({ 'text' => 'say "hello"' })
      expect(Toon.decode('text: " padded "')).to eq({ 'text' => ' padded ' })
      expect(Toon.decode('text: "  "')).to eq({ 'text' => '  ' })
      expect(Toon.decode('v: "true"')).to eq({ 'v' => 'true' })
      expect(Toon.decode('v: "42"')).to eq({ 'v' => '42' })
      expect(Toon.decode('v: "-7.5"')).to eq({ 'v' => '-7.5' })
    end
  end

  describe 'objects (keys)' do
    it 'parses quoted keys with special characters and escapes' do
      expect(Toon.decode('"order:id": 7')).to eq({ 'order:id' => 7 })
      expect(Toon.decode('"[index]": 5')).to eq({ '[index]' => 5 })
      expect(Toon.decode('"{key}": 5')).to eq({ '{key}' => 5 })
      expect(Toon.decode('"a,b": 1')).to eq({ 'a,b' => 1 })
      expect(Toon.decode('"full name": Ada')).to eq({ 'full name' => 'Ada' })
      expect(Toon.decode('"-lead": 1')).to eq({ '-lead' => 1 })
      expect(Toon.decode('" a ": 1')).to eq({ ' a ' => 1 })
      expect(Toon.decode('"123": x')).to eq({ '123' => 'x' })
      expect(Toon.decode('"": 1')).to eq({ '' => 1 })
    end

    it 'parses dotted keys as identifiers' do
      expect(Toon.decode('user.name: Ada')).to eq({ 'user.name' => 'Ada' })
      expect(Toon.decode('_private: 1')).to eq({ '_private' => 1 })
      expect(Toon.decode('user_name: 1')).to eq({ 'user_name' => 1 })
    end

    it 'unescapes control characters and quotes in keys' do
      expect(Toon.decode('"line\\nbreak": 1')).to eq({ "line\nbreak" => 1 })
      expect(Toon.decode('"tab\\there": 2')).to eq({ "tab\there" => 2 })
      expect(Toon.decode('"he said \\"hi\\"": 1')).to eq({ 'he said "hi"' => 1 })
    end
  end

  describe 'nested objects' do
    it 'parses deeply nested objects with indentation' do
      toon = "a:\n  b:\n    c: deep"
      expect(Toon.decode(toon)).to eq({ 'a' => { 'b' => { 'c' => 'deep' } } })
    end
  end

  describe 'arrays of primitives' do
    it 'parses string arrays inline' do
      toon = 'tags[3]: reading,gaming,coding'
      expect(Toon.decode(toon)).to eq({ 'tags' => ['reading', 'gaming', 'coding'] })
    end

    it 'parses number arrays inline' do
      toon = 'nums[3]: 1,2,3'
      expect(Toon.decode(toon)).to eq({ 'nums' => [1, 2, 3] })
    end

    it 'parses mixed primitive arrays inline' do
      toon = 'data[4]: x,y,true,10'
      expect(Toon.decode(toon)).to eq({ 'data' => ['x', 'y', true, 10] })
    end

    it 'parses empty arrays' do
      expect(Toon.decode('items[0]:')).to eq({ 'items' => [] })
    end

    it 'parses quoted strings in arrays including empty and whitespace-only' do
      expect(Toon.decode('items[1]: ""')).to eq({ 'items' => [''] })
      expect(Toon.decode('items[3]: a,"",b')).to eq({ 'items' => ['a', '', 'b'] })
      expect(Toon.decode('items[2]: " ","  "')).to eq({ 'items' => [' ', '  '] })
    end

    it 'parses strings with delimiters and structural tokens in arrays' do
      expect(Toon.decode('items[3]: a,"b,c","d:e"')).to eq({ 'items' => ['a', 'b,c', 'd:e'] })
      expect(Toon.decode('items[4]: x,"true","42","-3.14"')).to eq({ 'items' => ['x', 'true', '42', '-3.14'] })
      expect(Toon.decode('items[3]: "[5]","- item","{key}"')).to eq({ 'items' => ['[5]', '- item', '{key}'] })
    end
  end

  describe 'arrays of objects (tabular and list items)' do
    it 'parses tabular arrays of uniform objects' do
      toon = "items[2]{sku,qty,price}:\n  A1,2,9.99\n  B2,1,14.5"
      expect(Toon.decode(toon)).to eq({
        'items' => [
          { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
          { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
        ]
      })
    end

    it 'parses nulls and quoted values in tabular rows' do
      toon = "items[2]{id,value}:\n  1,null\n  2,\"test\""
      expect(Toon.decode(toon)).to eq({
        'items' => [
          { 'id' => 1, 'value' => nil },
          { 'id' => 2, 'value' => 'test' }
        ]
      })
    end

    it 'parses quoted header keys in tabular arrays' do
      toon = "items[2]{\"order:id\",\"full name\"}:\n  1,Ada\n  2,Bob"
      expect(Toon.decode(toon)).to eq({
        'items' => [
          { 'order:id' => 1, 'full name' => 'Ada' },
          { 'order:id' => 2, 'full name' => 'Bob' }
        ]
      })
    end

    it 'parses list arrays for non-uniform objects' do
      toon = "items[2]:\n  - id: 1\n    name: First\n  - id: 2\n    name: Second\n    extra: true"
      expect(Toon.decode(toon)).to eq({
        'items' => [
          { 'id' => 1, 'name' => 'First' },
          { 'id' => 2, 'name' => 'Second', 'extra' => true }
        ]
      })
    end

    it 'parses objects with nested values inside list items' do
      toon = "items[1]:\n  - id: 1\n    nested:\n      x: 1"
      expect(Toon.decode(toon)).to eq({
        'items' => [{ 'id' => 1, 'nested' => { 'x' => 1 } }]
      })
    end

    it 'parses nested tabular arrays as first field on hyphen line' do
      toon = "items[1]:\n  - users[2]{id,name}:\n    1,Ada\n    2,Bob\n    status: active"
      expect(Toon.decode(toon)).to eq({
        'items' => [
          {
            'users' => [
              { 'id' => 1, 'name' => 'Ada' },
              { 'id' => 2, 'name' => 'Bob' }
            ],
            'status' => 'active'
          }
        ]
      })
    end

    it 'parses objects containing arrays (including empty arrays) in list format' do
      toon = "items[1]:\n  - name: test\n    data[0]:"
      expect(Toon.decode(toon)).to eq({
        'items' => [{ 'name' => 'test', 'data' => [] }]
      })
    end

    it 'parses arrays of arrays within objects' do
      toon = "items[1]:\n  - matrix[2]:\n    - [2]: 1,2\n    - [2]: 3,4\n    name: grid"
      expect(Toon.decode(toon)).to eq({
        'items' => [{ 'matrix' => [[1, 2], [3, 4]], 'name' => 'grid' }]
      })
    end
  end

  describe 'arrays of arrays (primitives only)' do
    it 'parses nested arrays of primitives' do
      toon = "pairs[2]:\n  - [2]: a,b\n  - [2]: c,d"
      expect(Toon.decode(toon)).to eq({ 'pairs' => [['a', 'b'], ['c', 'd']] })
    end

    it 'parses quoted strings and mixed lengths in nested arrays' do
      toon = "pairs[2]:\n  - [2]: a,b\n  - [3]: \"c,d\",\"e:f\",\"true\""
      expect(Toon.decode(toon)).to eq({ 'pairs' => [['a', 'b'], ['c,d', 'e:f', 'true']] })
    end

    it 'parses empty inner arrays' do
      toon = "pairs[2]:\n  - [0]:\n  - [0]:"
      expect(Toon.decode(toon)).to eq({ 'pairs' => [[], []] })
    end

    it 'parses mixed-length inner arrays' do
      toon = "pairs[2]:\n  - [1]: 1\n  - [2]: 2,3"
      expect(Toon.decode(toon)).to eq({ 'pairs' => [[1], [2, 3]] })
    end
  end

  describe 'root arrays' do
    it 'parses root arrays of primitives (inline)' do
      toon = '[5]: x,y,"true",true,10'
      expect(Toon.decode(toon)).to eq(['x', 'y', 'true', true, 10])
    end

    it 'parses root arrays of uniform objects in tabular format' do
      toon = "[2]{id}:\n  1\n  2"
      expect(Toon.decode(toon)).to eq([{ 'id' => 1 }, { 'id' => 2 }])
    end

    it 'parses root arrays of non-uniform objects in list format' do
      toon = "[2]:\n  - id: 1\n  - id: 2\n    name: Ada"
      expect(Toon.decode(toon)).to eq([{ 'id' => 1 }, { 'id' => 2, 'name' => 'Ada' }])
    end

    it 'parses empty root arrays' do
      expect(Toon.decode('[0]:')).to eq([])
    end

    it 'parses root arrays of arrays' do
      toon = "[2]:\n  - [2]: 1,2\n  - [0]:"
      expect(Toon.decode(toon)).to eq([[1, 2], []])
    end
  end

  describe 'complex structures' do
    it 'parses mixed objects with arrays and nested objects' do
      toon = "user:\n  id: 123\n  name: Ada\n  tags[2]: reading,gaming\n  active: true\n  prefs[0]:"
      expect(Toon.decode(toon)).to eq({
        'user' => {
          'id' => 123,
          'name' => 'Ada',
          'tags' => ['reading', 'gaming'],
          'active' => true,
          'prefs' => []
        }
      })
    end
  end

  describe 'mixed arrays' do
    it 'parses arrays mixing primitives, objects and strings (list format)' do
      toon = "items[3]:\n  - 1\n  - a: 1\n  - text"
      expect(Toon.decode(toon)).to eq({ 'items' => [1, { 'a' => 1 }, 'text'] })
    end

    it 'parses arrays mixing objects and arrays' do
      toon = "items[2]:\n  - a: 1\n  - [2]: 1,2"
      expect(Toon.decode(toon)).to eq({ 'items' => [{ 'a' => 1 }, [1, 2]] })
    end
  end

  describe 'delimiter options' do
    it 'parses primitive arrays with tab delimiter' do
      toon = "tags[3\t]: reading\tgaming\tcoding"
      expect(Toon.decode(toon)).to eq({ 'tags' => ['reading', 'gaming', 'coding'] })
    end

    it 'parses primitive arrays with pipe delimiter' do
      toon = 'tags[3|]: reading|gaming|coding'
      expect(Toon.decode(toon)).to eq({ 'tags' => ['reading', 'gaming', 'coding'] })
    end

    it 'parses tabular arrays with tab delimiter' do
      toon = "items[2\t]{sku\tqty\tprice}:\n  A1\t2\t9.99\n  B2\t1\t14.5"
      expect(Toon.decode(toon)).to eq({
        'items' => [
          { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
          { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
        ]
      })
    end

    it 'parses tabular arrays with pipe delimiter' do
      toon = "items[2|]{sku|qty|price}:\n  A1|2|9.99\n  B2|1|14.5"
      expect(Toon.decode(toon)).to eq({
        'items' => [
          { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
          { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
        ]
      })
    end

    it 'parses values containing the active delimiter when quoted' do
      toon = "items[3\t]: a\t\"b\\tc\"\td"
      expect(Toon.decode(toon)).to eq({ 'items' => ['a', "b\tc", 'd'] })
    end

    it 'does not split on commas when using non-comma delimiter' do
      toon = "items[2\t]: a,b\tc,d"
      expect(Toon.decode(toon)).to eq({ 'items' => ['a,b', 'c,d'] })
    end
  end

  describe 'length marker option' do
    it 'accepts length marker on primitive arrays' do
      expect(Toon.decode('tags[#3]: reading,gaming,coding')).to eq({ 'tags' => ['reading', 'gaming', 'coding'] })
    end

    it 'accepts length marker on empty arrays' do
      expect(Toon.decode('items[#0]:')).to eq({ 'items' => [] })
    end

    it 'accepts length marker on tabular arrays' do
      toon = "items[#2]{sku,qty,price}:\n  A1,2,9.99\n  B2,1,14.5"
      expect(Toon.decode(toon)).to eq({
        'items' => [
          { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
          { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
        ]
      })
    end

    it 'accepts length marker on nested arrays' do
      toon = "pairs[#2]:\n  - [#2]: a,b\n  - [#2]: c,d"
      expect(Toon.decode(toon)).to eq({ 'pairs' => [['a', 'b'], ['c', 'd']] })
    end

    it 'works with custom delimiters and length marker' do
      expect(Toon.decode('tags[#3|]: reading|gaming|coding')).to eq({ 'tags' => ['reading', 'gaming', 'coding'] })
    end
  end

  describe 'validation and error handling' do
    describe 'length and structure errors' do
      it 'throws on array length mismatch (inline primitives)' do
        toon = 'tags[2]: a,b,c'
        expect { Toon.decode(toon) }.to raise_error(RangeError)
      end

      it 'throws on array length mismatch (list format)' do
        toon = "items[1]:\n  - 1\n  - 2"
        expect { Toon.decode(toon) }.to raise_error(RangeError)
      end

      it 'throws when tabular row value count does not match header field count' do
        toon = "items[2]{id,name}:\n  1,Ada\n  2"
        expect { Toon.decode(toon) }.to raise_error(RangeError)
      end

      it 'throws when tabular row count does not match header length' do
        toon = "[1]{id}:\n  1\n  2"
        expect { Toon.decode(toon) }.to raise_error(RangeError)
      end

      it 'throws on invalid escape sequences' do
        expect { Toon.decode('"a\\x"') }.to raise_error(SyntaxError)
        expect { Toon.decode('"unterminated') }.to raise_error(SyntaxError)
      end

      it 'throws on missing colon in key-value context' do
        expect { Toon.decode("a:\n  user") }.to raise_error(SyntaxError)
      end
    end

    describe 'strict mode: indentation validation' do
      it 'throws when object field has non-multiple indentation' do
        toon = "a:\n   b: 1" # 3 spaces with indent=2
        expect { Toon.decode(toon) }.to raise_error(SyntaxError, /indentation/)
        expect { Toon.decode(toon) }.to raise_error(/exact multiple/)
      end

      it 'throws when list item has non-multiple indentation' do
        toon = "items[2]:\n   - id: 1\n   - id: 2" # 3 spaces
        expect { Toon.decode(toon) }.to raise_error(SyntaxError, /indentation/)
      end

      it 'throws with custom indent size when non-multiple' do
        toon = "a:\n   b: 1" # 3 spaces with indent=4
        expect { Toon.decode(toon, indent: 4) }.to raise_error(/exact multiple of 4/)
      end

      it 'accepts correct indentation with custom indent size' do
        toon = "a:\n    b: 1" # 4 spaces with indent=4
        expect(Toon.decode(toon, indent: 4)).to eq({ 'a' => { 'b' => 1 } })
      end

      it 'throws when tab character used in indentation' do
        toon = "a:\n\tb: 1"
        expect { Toon.decode(toon) }.to raise_error(SyntaxError, /tab/)
      end

      it 'throws when mixed tabs and spaces in indentation' do
        toon = "a:\n \tb: 1" # space + tab
        expect { Toon.decode(toon) }.to raise_error(SyntaxError, /tab/)
      end

      it 'accepts tabs in quoted string values' do
        toon = "text: \"hello\tworld\""
        expect(Toon.decode(toon)).to eq({ 'text' => "hello\tworld" })
      end

      it 'accepts non-multiple indentation when strict=false' do
        toon = "a:\n   b: 1" # 3 spaces with indent=2
        expect(Toon.decode(toon, strict: false)).to eq({ 'a' => { 'b' => 1 } })
      end

      it 'accepts deeply nested non-multiples when strict=false' do
        toon = "a:\n   b:\n     c: 1" # 3 and 5 spaces
        expect(Toon.decode(toon, strict: false)).to eq({ 'a' => { 'b' => { 'c' => 1 } } })
      end
    end

    describe 'strict mode: blank lines in arrays' do
      it 'throws on blank line inside list array' do
        toon = "items[3]:\n  - a\n\n  - b\n  - c"
        expect { Toon.decode(toon) }.to raise_error(SyntaxError, /blank line/)
        expect { Toon.decode(toon) }.to raise_error(/list array/)
      end

      it 'throws on blank line inside tabular array' do
        toon = "items[2]{id}:\n  1\n\n  2"
        expect { Toon.decode(toon) }.to raise_error(SyntaxError, /blank line/)
        expect { Toon.decode(toon) }.to raise_error(/tabular array/)
      end

      it 'accepts blank line between root-level fields' do
        toon = "a: 1\n\nb: 2"
        expect(Toon.decode(toon)).to eq({ 'a' => 1, 'b' => 2 })
      end

      it 'accepts blank line after array ends' do
        toon = "items[1]:\n  - a\n\nb: 2"
        expect(Toon.decode(toon)).to eq({ 'items' => ['a'], 'b' => 2 })
      end

      it 'ignores blank lines inside list array when strict=false' do
        toon = "items[3]:\n  - a\n\n  - b\n  - c"
        expect(Toon.decode(toon, strict: false)).to eq({ 'items' => ['a', 'b', 'c'] })
      end

      it 'ignores blank lines inside tabular array when strict=false' do
        toon = "items[2]{id,name}:\n  1,Alice\n\n  2,Bob"
        expect(Toon.decode(toon, strict: false)).to eq({
          'items' => [
            { 'id' => 1, 'name' => 'Alice' },
            { 'id' => 2, 'name' => 'Bob' }
          ]
        })
      end
    end
  end

  describe 'roundtrip encode/decode' do
    it 'roundtrips simple objects' do
      obj = { 'id' => 123, 'name' => 'Ada', 'active' => true }
      encoded = Toon.encode(obj)
      decoded = Toon.decode(encoded)
      expect(decoded).to eq(obj)
    end

    it 'roundtrips arrays' do
      arr = ['a', 'b', 'c']
      encoded = Toon.encode({ 'items' => arr })
      decoded = Toon.decode(encoded)
      expect(decoded).to eq({ 'items' => arr })
    end

    it 'roundtrips nested objects' do
      obj = { 'user' => { 'profile' => { 'name' => 'Ada' } } }
      encoded = Toon.encode(obj)
      decoded = Toon.decode(encoded)
      expect(decoded).to eq(obj)
    end

    it 'roundtrips tabular arrays' do
      obj = {
        'items' => [
          { 'id' => 1, 'name' => 'First' },
          { 'id' => 2, 'name' => 'Second' }
        ]
      }
      encoded = Toon.encode(obj)
      decoded = Toon.decode(encoded)
      expect(decoded).to eq(obj)
    end
  end
end
