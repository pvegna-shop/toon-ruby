# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Toon do
  describe 'primitives' do
    it 'encodes safe strings without quotes' do
      expect(Toon.encode('hello')).to eq('hello')
      expect(Toon.encode('Ada_99')).to eq('Ada_99')
    end

    it 'quotes empty string' do
      expect(Toon.encode('')).to eq('""')
    end

    it 'quotes strings that look like booleans or numbers' do
      expect(Toon.encode('true')).to eq('"true"')
      expect(Toon.encode('false')).to eq('"false"')
      expect(Toon.encode('null')).to eq('"null"')
      expect(Toon.encode('42')).to eq('"42"')
      expect(Toon.encode('-3.14')).to eq('"-3.14"')
      expect(Toon.encode('1e-6')).to eq('"1e-6"')
      expect(Toon.encode('05')).to eq('"05"')
    end

    it 'escapes control characters in strings' do
      expect(Toon.encode("line1\nline2")).to eq('"line1\nline2"')
      expect(Toon.encode("tab\there")).to eq('"tab\there"')
      expect(Toon.encode("return\rcarriage")).to eq('"return\rcarriage"')
      expect(Toon.encode('C:\Users\path')).to eq('"C:\\Users\\path"')
    end

    it 'quotes strings with structural characters' do
      expect(Toon.encode('[3]: x,y')).to eq('"[3]: x,y"')
      expect(Toon.encode('- item')).to eq('"- item"')
      expect(Toon.encode('[test]')).to eq('"[test]"')
      expect(Toon.encode('{key}')).to eq('"{key}"')
    end

    it 'handles Unicode and emoji' do
      expect(Toon.encode('café')).to eq('café')
      expect(Toon.encode('你好')).to eq('你好')
      expect(Toon.encode('🚀')).to eq('🚀')
      expect(Toon.encode('hello 👋 world')).to eq('hello 👋 world')
    end

    it 'encodes numbers' do
      expect(Toon.encode(42)).to eq('42')
      expect(Toon.encode(3.14)).to eq('3.14')
      expect(Toon.encode(-7)).to eq('-7')
      expect(Toon.encode(0)).to eq('0')
    end

    it 'handles special numeric values' do
      expect(Toon.encode(-0.0)).to eq('0')
      expect(Toon.encode(1e6)).to eq('1000000.0')
      expect(Toon.encode(1e-6)).to eq('1.0e-06')
    end

    it 'encodes booleans' do
      expect(Toon.encode(true)).to eq('true')
      expect(Toon.encode(false)).to eq('false')
    end

    it 'encodes null' do
      expect(Toon.encode(nil)).to eq('null')
    end
  end

  describe 'objects (simple)' do
    it 'preserves key order in objects' do
      obj = {
        'id' => 123,
        'name' => 'Ada',
        'active' => true
      }
      expect(Toon.encode(obj)).to eq("id: 123\nname: Ada\nactive: true")
    end

    it 'encodes null values in objects' do
      obj = { 'id' => 123, 'value' => nil }
      expect(Toon.encode(obj)).to eq("id: 123\nvalue: null")
    end

    it 'encodes empty objects as empty string' do
      expect(Toon.encode({})).to eq('')
    end

    it 'quotes string values with special characters' do
      expect(Toon.encode({ 'note' => 'a:b' })).to eq('note: "a:b"')
      expect(Toon.encode({ 'note' => 'a,b' })).to eq('note: "a,b"')
      expect(Toon.encode({ 'text' => "line1\nline2" })).to eq('text: "line1\nline2"')
      expect(Toon.encode({ 'text' => 'say "hello"' })).to eq('text: "say \"hello\""')
    end

    it 'quotes string values with leading/trailing spaces' do
      expect(Toon.encode({ 'text' => ' padded ' })).to eq('text: " padded "')
      expect(Toon.encode({ 'text' => '  ' })).to eq('text: "  "')
    end

    it 'quotes string values that look like booleans/numbers' do
      expect(Toon.encode({ 'v' => 'true' })).to eq('v: "true"')
      expect(Toon.encode({ 'v' => '42' })).to eq('v: "42"')
      expect(Toon.encode({ 'v' => '-7.5' })).to eq('v: "-7.5"')
    end
  end

  describe 'objects (keys)' do
    it 'quotes keys with special characters' do
      expect(Toon.encode({ 'order:id' => 7 })).to eq('"order:id": 7')
      expect(Toon.encode({ '[index]' => 5 })).to eq('"[index]": 5')
      expect(Toon.encode({ '{key}' => 5 })).to eq('"{key}": 5')
      expect(Toon.encode({ 'a,b' => 1 })).to eq('"a,b": 1')
    end

    it 'quotes keys with spaces or leading hyphens' do
      expect(Toon.encode({ 'full name' => 'Ada' })).to eq('"full name": Ada')
      expect(Toon.encode({ '-lead' => 1 })).to eq('"-lead": 1')
      expect(Toon.encode({ ' a ' => 1 })).to eq('" a ": 1')
    end

    it 'quotes numeric keys' do
      expect(Toon.encode({ '123' => 'x' })).to eq('"123": x')
    end

    it 'quotes empty string key' do
      expect(Toon.encode({ '' => 1 })).to eq('"": 1')
    end

    it 'escapes control characters in keys' do
      expect(Toon.encode({ "line\nbreak" => 1 })).to eq('"line\nbreak": 1')
      expect(Toon.encode({ "tab\there" => 2 })).to eq('"tab\there": 2')
    end

    it 'escapes quotes in keys' do
      expect(Toon.encode({ 'he said "hi"' => 1 })).to eq('"he said \"hi\"": 1')
    end
  end

  describe 'nested objects' do
    it 'encodes deeply nested objects' do
      obj = {
        'a' => {
          'b' => {
            'c' => 'deep'
          }
        }
      }
      expect(Toon.encode(obj)).to eq("a:\n  b:\n    c: deep")
    end

    it 'encodes empty nested object' do
      expect(Toon.encode({ 'user' => {} })).to eq('user:')
    end
  end

  describe 'arrays of primitives' do
    it 'encodes string arrays inline' do
      obj = { 'tags' => ['reading', 'gaming'] }
      expect(Toon.encode(obj)).to eq('tags[2]: reading,gaming')
    end

    it 'encodes number arrays inline' do
      obj = { 'nums' => [1, 2, 3] }
      expect(Toon.encode(obj)).to eq('nums[3]: 1,2,3')
    end

    it 'encodes mixed primitive arrays inline' do
      obj = { 'data' => ['x', 'y', true, 10] }
      expect(Toon.encode(obj)).to eq('data[4]: x,y,true,10')
    end

    it 'encodes empty arrays' do
      obj = { 'items' => [] }
      expect(Toon.encode(obj)).to eq('items[0]:')
    end

    it 'handles empty string in arrays' do
      obj = { 'items' => [''] }
      expect(Toon.encode(obj)).to eq('items[1]: ""')
      obj2 = { 'items' => ['a', '', 'b'] }
      expect(Toon.encode(obj2)).to eq('items[3]: a,"",b')
    end

    it 'handles whitespace-only strings in arrays' do
      obj = { 'items' => [' ', '  '] }
      expect(Toon.encode(obj)).to eq('items[2]: " ","  "')
    end

    it 'quotes array strings with special characters' do
      obj = { 'items' => ['a', 'b,c', 'd:e'] }
      expect(Toon.encode(obj)).to eq('items[3]: a,"b,c","d:e"')
    end

    it 'quotes strings that look like booleans/numbers in arrays' do
      obj = { 'items' => ['x', 'true', '42', '-3.14'] }
      expect(Toon.encode(obj)).to eq('items[4]: x,"true","42","-3.14"')
    end

    it 'quotes strings with structural meanings in arrays' do
      obj = { 'items' => ['[5]', '- item', '{key}'] }
      expect(Toon.encode(obj)).to eq('items[3]: "[5]","- item","{key}"')
    end
  end

  describe 'arrays of objects (tabular and list items)' do
    it 'encodes arrays of similar objects in tabular format' do
      obj = {
        'items' => [
          { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
          { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{sku,qty,price}:\n  A1,2,9.99\n  B2,1,14.5")
    end

    it 'handles null values in tabular format' do
      obj = {
        'items' => [
          { 'id' => 1, 'value' => nil },
          { 'id' => 2, 'value' => 'test' }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{id,value}:\n  1,null\n  2,test")
    end

    it 'quotes strings containing delimiters in tabular rows' do
      obj = {
        'items' => [
          { 'sku' => 'A,1', 'desc' => 'cool', 'qty' => 2 },
          { 'sku' => 'B2', 'desc' => 'wip: test', 'qty' => 1 }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{sku,desc,qty}:\n  \"A,1\",cool,2\n  B2,\"wip: test\",1")
    end

    it 'quotes ambiguous strings in tabular rows' do
      obj = {
        'items' => [
          { 'id' => 1, 'status' => 'true' },
          { 'id' => 2, 'status' => 'false' }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{id,status}:\n  1,\"true\"\n  2,\"false\"")
    end

    it 'handles tabular arrays with keys needing quotes' do
      obj = {
        'items' => [
          { 'order:id' => 1, 'full name' => 'Ada' },
          { 'order:id' => 2, 'full name' => 'Bob' }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{\"order:id\",\"full name\"}:\n  1,Ada\n  2,Bob")
    end

    it 'uses list format for objects with different fields' do
      obj = {
        'items' => [
          { 'id' => 1, 'name' => 'First' },
          { 'id' => 2, 'name' => 'Second', 'extra' => true }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[2]:\n" \
        "  - id: 1\n" \
        "    name: First\n" \
        "  - id: 2\n" \
        "    name: Second\n" \
        "    extra: true"
      )
    end

    it 'uses list format for objects with nested values' do
      obj = {
        'items' => [
          { 'id' => 1, 'nested' => { 'x' => 1 } }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - id: 1\n" \
        "    nested:\n" \
        "      x: 1"
      )
    end

    it 'preserves field order in list items' do
      obj = { 'items' => [{ 'nums' => [1, 2, 3], 'name' => 'test' }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - nums[3]: 1,2,3\n" \
        "    name: test"
      )
    end

    it 'preserves field order when primitive appears first' do
      obj = { 'items' => [{ 'name' => 'test', 'nums' => [1, 2, 3] }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - name: test\n" \
        "    nums[3]: 1,2,3"
      )
    end

    it 'uses list format for objects containing arrays of arrays' do
      obj = {
        'items' => [
          { 'matrix' => [[1, 2], [3, 4]], 'name' => 'grid' }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - matrix[2]:\n" \
        "    - [2]: 1,2\n" \
        "    - [2]: 3,4\n" \
        "    name: grid"
      )
    end

    it 'uses tabular format for nested uniform object arrays' do
      obj = {
        'items' => [
          { 'users' => [{ 'id' => 1, 'name' => 'Ada' }, { 'id' => 2, 'name' => 'Bob' }], 'status' => 'active' }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - users[2]{id,name}:\n" \
        "    1,Ada\n" \
        "    2,Bob\n" \
        "    status: active"
      )
    end

    it 'uses list format for nested object arrays with mismatched keys' do
      obj = {
        'items' => [
          { 'users' => [{ 'id' => 1, 'name' => 'Ada' }, { 'id' => 2 }], 'status' => 'active' }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - users[2]:\n" \
        "    - id: 1\n" \
        "      name: Ada\n" \
        "    - id: 2\n" \
        "    status: active"
      )
    end

    it 'uses list format for objects with multiple array fields' do
      obj = { 'items' => [{ 'nums' => [1, 2], 'tags' => ['a', 'b'], 'name' => 'test' }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - nums[2]: 1,2\n" \
        "    tags[2]: a,b\n" \
        "    name: test"
      )
    end

    it 'uses list format for objects with only array fields' do
      obj = { 'items' => [{ 'nums' => [1, 2, 3], 'tags' => ['a', 'b'] }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - nums[3]: 1,2,3\n" \
        "    tags[2]: a,b"
      )
    end

    it 'handles objects with empty arrays in list format' do
      obj = {
        'items' => [
          { 'name' => 'test', 'data' => [] }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - name: test\n" \
        "    data[0]:"
      )
    end

    it 'places first field of nested tabular arrays on hyphen line' do
      obj = { 'items' => [{ 'users' => [{ 'id' => 1 }, { 'id' => 2 }], 'note' => 'x' }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - users[2]{id}:\n" \
        "    1\n" \
        "    2\n" \
        "    note: x"
      )
    end

    it 'places empty arrays on hyphen line when first' do
      obj = { 'items' => [{ 'data' => [], 'name' => 'x' }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - data[0]:\n" \
        "    name: x"
      )
    end

    it 'uses field order from first object for tabular headers' do
      obj = {
        'items' => [
          { 'a' => 1, 'b' => 2, 'c' => 3 },
          { 'c' => 30, 'b' => 20, 'a' => 10 }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{a,b,c}:\n  1,2,3\n  10,20,30")
    end

    it 'uses list format for one object with nested column' do
      obj = {
        'items' => [
          { 'id' => 1, 'data' => 'string' },
          { 'id' => 2, 'data' => { 'nested' => true } }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[2]:\n" \
        "  - id: 1\n" \
        "    data: string\n" \
        "  - id: 2\n" \
        "    data:\n" \
        "      nested: true"
      )
    end
  end

  describe 'arrays of arrays (primitives only)' do
    it 'encodes nested arrays of primitives' do
      obj = {
        'pairs' => [['a', 'b'], ['c', 'd']]
      }
      expect(Toon.encode(obj)).to eq("pairs[2]:\n  - [2]: a,b\n  - [2]: c,d")
    end

    it 'quotes strings containing delimiters in nested arrays' do
      obj = {
        'pairs' => [['a', 'b'], ['c,d', 'e:f', 'true']]
      }
      expect(Toon.encode(obj)).to eq("pairs[2]:\n  - [2]: a,b\n  - [3]: \"c,d\",\"e:f\",\"true\"")
    end

    it 'handles empty inner arrays' do
      obj = {
        'pairs' => [[], []]
      }
      expect(Toon.encode(obj)).to eq("pairs[2]:\n  - [0]:\n  - [0]:")
    end

    it 'handles mixed-length inner arrays' do
      obj = {
        'pairs' => [[1], [2, 3]]
      }
      expect(Toon.encode(obj)).to eq("pairs[2]:\n  - [1]: 1\n  - [2]: 2,3")
    end
  end

  describe 'root arrays' do
    it 'encodes arrays of primitives at root level' do
      arr = ['x', 'y', 'true', true, 10]
      expect(Toon.encode(arr)).to eq('[5]: x,y,"true",true,10')
    end

    it 'encodes arrays of similar objects in tabular format' do
      arr = [{ 'id' => 1 }, { 'id' => 2 }]
      expect(Toon.encode(arr)).to eq("[2]{id}:\n  1\n  2")
    end

    it 'encodes arrays of different objects in list format' do
      arr = [{ 'id' => 1 }, { 'id' => 2, 'name' => 'Ada' }]
      expect(Toon.encode(arr)).to eq("[2]:\n  - id: 1\n  - id: 2\n    name: Ada")
    end

    it 'encodes empty arrays at root level' do
      expect(Toon.encode([])).to eq('[0]:')
    end

    it 'encodes arrays of arrays at root level' do
      arr = [[1, 2], []]
      expect(Toon.encode(arr)).to eq("[2]:\n  - [2]: 1,2\n  - [0]:")
    end
  end

  describe 'complex structures' do
    it 'encodes objects with mixed arrays and nested objects' do
      obj = {
        'user' => {
          'id' => 123,
          'name' => 'Ada',
          'tags' => ['reading', 'gaming'],
          'active' => true,
          'prefs' => []
        }
      }
      expect(Toon.encode(obj)).to eq(
        "user:\n" \
        "  id: 123\n" \
        "  name: Ada\n" \
        "  tags[2]: reading,gaming\n" \
        "  active: true\n" \
        "  prefs[0]:"
      )
    end
  end

  describe 'mixed arrays' do
    it 'uses list format for arrays mixing primitives and objects' do
      obj = {
        'items' => [1, { 'a' => 1 }, 'text']
      }
      expect(Toon.encode(obj)).to eq(
        "items[3]:\n" \
        "  - 1\n" \
        "  - a: 1\n" \
        "  - text"
      )
    end

    it 'uses list format for arrays mixing objects and arrays' do
      obj = {
        'items' => [{ 'a' => 1 }, [1, 2]]
      }
      expect(Toon.encode(obj)).to eq(
        "items[2]:\n" \
        "  - a: 1\n" \
        "  - [2]: 1,2"
      )
    end
  end

  describe 'whitespace and formatting invariants' do
    it 'produces no trailing spaces at end of lines' do
      obj = {
        'user' => {
          'id' => 123,
          'name' => 'Ada'
        },
        'items' => ['a', 'b']
      }
      result = Toon.encode(obj)
      lines = result.split("\n")
      lines.each do |line|
        expect(line).not_to match(/ $/)
      end
    end

    it 'produces no trailing newline at end of output' do
      obj = { 'id' => 123 }
      result = Toon.encode(obj)
      expect(result).not_to match(/\n$/)
    end
  end

  describe 'non-JSON-serializable values' do
    it 'converts Symbol to string' do
      expect(Toon.encode(:hello)).to eq('hello')
      expect(Toon.encode({ id: 456 })).to eq('id: 456')
    end

    it 'converts Time to ISO string' do
      time = Time.utc(2025, 1, 1, 0, 0, 0)
      expect(Toon.encode(time)).to eq('"2025-01-01T00:00:00Z"')
      expect(Toon.encode({ created: time })).to eq('created: "2025-01-01T00:00:00Z"')
    end

    it 'converts non-finite numbers to null' do
      expect(Toon.encode(Float::INFINITY)).to eq('null')
      expect(Toon.encode(-Float::INFINITY)).to eq('null')
      expect(Toon.encode(Float::NAN)).to eq('null')
    end
  end

  describe 'delimiter options' do
    describe 'basic delimiter usage' do
      [
        { delimiter: "\t", name: 'tab', expected: "reading\tgaming\tcoding" },
        { delimiter: '|', name: 'pipe', expected: 'reading|gaming|coding' },
        { delimiter: ',', name: 'comma', expected: 'reading,gaming,coding' }
      ].each do |test_case|
        it "encodes primitive arrays with #{test_case[:name]}" do
          obj = { 'tags' => ['reading', 'gaming', 'coding'] }
          delimiter_suffix = test_case[:delimiter] != ',' ? test_case[:delimiter] : ''
          expect(Toon.encode(obj, delimiter: test_case[:delimiter])).to eq("tags[3#{delimiter_suffix}]: #{test_case[:expected]}")
        end
      end

      [
        { delimiter: "\t", name: 'tab', expected: "items[2\t]{sku\tqty\tprice}:\n  A1\t2\t9.99\n  B2\t1\t14.5" },
        { delimiter: '|', name: 'pipe', expected: "items[2|]{sku|qty|price}:\n  A1|2|9.99\n  B2|1|14.5" }
      ].each do |test_case|
        it "encodes tabular arrays with #{test_case[:name]}" do
          obj = {
            'items' => [
              { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
              { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
            ]
          }
          expect(Toon.encode(obj, delimiter: test_case[:delimiter])).to eq(test_case[:expected])
        end
      end

      [
        { delimiter: "\t", name: 'tab', expected: "pairs[2\t]:\n  - [2\t]: a\tb\n  - [2\t]: c\td" },
        { delimiter: '|', name: 'pipe', expected: "pairs[2|]:\n  - [2|]: a|b\n  - [2|]: c|d" }
      ].each do |test_case|
        it "encodes nested arrays with #{test_case[:name]}" do
          obj = { 'pairs' => [['a', 'b'], ['c', 'd']] }
          expect(Toon.encode(obj, delimiter: test_case[:delimiter])).to eq(test_case[:expected])
        end
      end

      [
        { delimiter: "\t", name: 'tab' },
        { delimiter: '|', name: 'pipe' }
      ].each do |test_case|
        it "encodes root arrays with #{test_case[:name]}" do
          arr = ['x', 'y', 'z']
          expect(Toon.encode(arr, delimiter: test_case[:delimiter])).to eq("[3#{test_case[:delimiter]}]: x#{test_case[:delimiter]}y#{test_case[:delimiter]}z")
        end
      end

      [
        { delimiter: "\t", name: 'tab', expected: "[2\t]{id}:\n  1\n  2" },
        { delimiter: '|', name: 'pipe', expected: "[2|]{id}:\n  1\n  2" }
      ].each do |test_case|
        it "encodes root arrays of objects with #{test_case[:name]}" do
          arr = [{ 'id' => 1 }, { 'id' => 2 }]
          expect(Toon.encode(arr, delimiter: test_case[:delimiter])).to eq(test_case[:expected])
        end
      end
    end

    describe 'delimiter-aware quoting' do
      [
        { delimiter: "\t", name: 'tab', char: "\t", input: ['a', "b\tc", 'd'], expected: "a\t\"b\\tc\"\td" },
        { delimiter: '|', name: 'pipe', char: '|', input: ['a', 'b|c', 'd'], expected: 'a|"b|c"|d' }
      ].each do |test_case|
        it "quotes strings containing #{test_case[:name]}" do
          expect(Toon.encode({ 'items' => test_case[:input] }, delimiter: test_case[:delimiter])).to eq("items[#{test_case[:input].length}#{test_case[:delimiter]}]: #{test_case[:expected]}")
        end
      end

      [
        { delimiter: "\t", name: 'tab', input: ['a,b', 'c,d'], expected: "a,b\tc,d" },
        { delimiter: '|', name: 'pipe', input: ['a,b', 'c,d'], expected: 'a,b|c,d' }
      ].each do |test_case|
        it "does not quote commas with #{test_case[:name]}" do
          expect(Toon.encode({ 'items' => test_case[:input] }, delimiter: test_case[:delimiter])).to eq("items[#{test_case[:input].length}#{test_case[:delimiter]}]: #{test_case[:expected]}")
        end
      end

      it 'quotes tabular values containing the delimiter' do
        obj = {
          'items' => [
            { 'id' => 1, 'note' => 'a,b' },
            { 'id' => 2, 'note' => 'c,d' }
          ]
        }
        expect(Toon.encode(obj, delimiter: ',')).to eq("items[2]{id,note}:\n  1,\"a,b\"\n  2,\"c,d\"")
        expect(Toon.encode(obj, delimiter: "\t")).to eq("items[2\t]{id\tnote}:\n  1\ta,b\n  2\tc,d")
      end

      it 'does not quote commas in object values with non-comma delimiter' do
        expect(Toon.encode({ 'note' => 'a,b' }, delimiter: '|')).to eq('note: a,b')
        expect(Toon.encode({ 'note' => 'a,b' }, delimiter: "\t")).to eq('note: a,b')
      end

      it 'quotes nested array values containing the delimiter' do
        expect(Toon.encode({ 'pairs' => [['a', 'b|c']] }, delimiter: '|')).to eq("pairs[1|]:\n  - [2|]: a|\"b|c\"")
        expect(Toon.encode({ 'pairs' => [['a', "b\tc"]] }, delimiter: "\t")).to eq("pairs[1\t]:\n  - [2\t]: a\t\"b\\tc\"")
      end
    end

    describe 'delimiter-independent quoting rules' do
      it 'preserves ambiguity quoting regardless of delimiter' do
        obj = { 'items' => ['true', '42', '-3.14'] }
        expect(Toon.encode(obj, delimiter: '|')).to eq('items[3|]: "true"|"42"|"-3.14"')
        expect(Toon.encode(obj, delimiter: "\t")).to eq("items[3\t]: \"true\"\t\"42\"\t\"-3.14\"")
      end

      it 'preserves structural quoting regardless of delimiter' do
        obj = { 'items' => ['[5]', '{key}', '- item'] }
        expect(Toon.encode(obj, delimiter: '|')).to eq('items[3|]: "[5]"|"{key}"|"- item"')
        expect(Toon.encode(obj, delimiter: "\t")).to eq("items[3\t]: \"[5]\"\t\"{key}\"\t\"- item\"")
      end

      it 'quotes keys containing the delimiter' do
        expect(Toon.encode({ 'a|b' => 1 }, delimiter: '|')).to eq('"a|b": 1')
        expect(Toon.encode({ "a\tb" => 1 }, delimiter: "\t")).to eq("\"a\\tb\": 1")
      end

      it 'quotes tabular headers containing the delimiter' do
        obj = { 'items' => [{ 'a|b' => 1 }, { 'a|b' => 2 }] }
        expect(Toon.encode(obj, delimiter: '|')).to eq("items[2|]{\"a|b\"}:\n  1\n  2")
      end

      it 'header uses the active delimiter' do
        obj = { 'items' => [{ 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 }] }
        expect(Toon.encode(obj, delimiter: '|')).to eq("items[2|]{a|b}:\n  1|2\n  3|4")
        expect(Toon.encode(obj, delimiter: "\t")).to eq("items[2\t]{a\tb}:\n  1\t2\n  3\t4")
      end
    end

    describe 'formatting invariants with delimiters' do
      [
        { delimiter: "\t", name: 'tab' },
        { delimiter: '|', name: 'pipe' }
      ].each do |test_case|
        it "produces no trailing spaces with #{test_case[:name]}" do
          obj = {
            'user' => { 'id' => 123, 'name' => 'Ada' },
            'items' => ['a', 'b']
          }
          result = Toon.encode(obj, delimiter: test_case[:delimiter])
          lines = result.split("\n")
          lines.each do |line|
            expect(line).not_to match(/ $/)
          end
        end
      end

      [
        { delimiter: "\t", name: 'tab' },
        { delimiter: '|', name: 'pipe' }
      ].each do |test_case|
        it "produces no trailing newline with #{test_case[:name]}" do
          obj = { 'id' => 123 }
          result = Toon.encode(obj, delimiter: test_case[:delimiter])
          expect(result).not_to match(/\n$/)
        end
      end
    end
  end

  describe 'length marker option' do
    it 'adds length marker to primitive arrays' do
      obj = { 'tags' => ['reading', 'gaming', 'coding'] }
      expect(Toon.encode(obj, length_marker: '#')).to eq('tags[#3]: reading,gaming,coding')
    end

    it 'handles empty arrays' do
      expect(Toon.encode({ 'items' => [] }, length_marker: '#')).to eq('items[#0]:')
    end

    it 'adds length marker to tabular arrays' do
      obj = {
        'items' => [
          { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
          { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
        ]
      }
      expect(Toon.encode(obj, length_marker: '#')).to eq("items[#2]{sku,qty,price}:\n  A1,2,9.99\n  B2,1,14.5")
    end

    it 'adds length marker to nested arrays' do
      obj = { 'pairs' => [['a', 'b'], ['c', 'd']] }
      expect(Toon.encode(obj, length_marker: '#')).to eq("pairs[#2]:\n  - [#2]: a,b\n  - [#2]: c,d")
    end

    it 'works with delimiter option' do
      obj = { 'tags' => ['reading', 'gaming', 'coding'] }
      expect(Toon.encode(obj, length_marker: '#', delimiter: '|')).to eq('tags[#3|]: reading|gaming|coding')
    end

    it 'default is false (no length marker)' do
      obj = { 'tags' => ['reading', 'gaming', 'coding'] }
      expect(Toon.encode(obj)).to eq('tags[3]: reading,gaming,coding')
    end
  end

  describe 'normalize_on option' do
    describe 'basic normalization' do
      it 'normalizes simple array of hashes with missing keys' do
        input = { 'columns' => [{ 'one' => 1 }, { 'one' => 1, 'two' => 2 }] }
        result = Toon.encode(input, normalize_on: 'columns')
        # After normalization, both hashes should have 'one' and 'two' keys
        expect(result).to eq("columns[2]{one,two}:\n  1,null\n  1,2")
      end

      it 'normalizes with nil as default for missing keys' do
        input = { 'data' => [{ 'a' => 1, 'b' => 2 }, { 'a' => 3 }, { 'c' => 5 }] }
        result = Toon.encode(input, normalize_on: 'data')
        # All hashes should have keys: a, b, c
        expect(result).to eq("data[3]{a,b,c}:\n  1,2,null\n  3,null,null\n  null,null,5")
      end

      it 'does not modify input when normalize_on is nil' do
        input = { 'columns' => [{ 'one' => 1 }, { 'one' => 1, 'two' => 2 }] }
        result = Toon.encode(input, normalize_on: nil)
        # Without normalize_on, objects have different keys so should use list format
        expect(result).to eq(
          "columns[2]:\n" \
          "  - one: 1\n" \
          "  - one: 1\n" \
          "    two: 2"
        )
      end

      it 'does not modify input when normalize_on key does not exist' do
        input = { 'columns' => [{ 'one' => 1 }, { 'one' => 1, 'two' => 2 }] }
        result = Toon.encode(input, normalize_on: 'nonexistent')
        # Should behave as normal without normalization
        expect(result).to eq(
          "columns[2]:\n" \
          "  - one: 1\n" \
          "  - one: 1\n" \
          "    two: 2"
        )
      end

      it 'handles empty arrays' do
        input = { 'columns' => [] }
        result = Toon.encode(input, normalize_on: 'columns')
        expect(result).to eq('columns[0]:')
      end

      it 'handles single hash in array' do
        input = { 'columns' => [{ 'one' => 1 }] }
        result = Toon.encode(input, normalize_on: 'columns')
        expect(result).to eq("columns[1]{one}:\n  1")
      end
    end

    describe 'nested normalization' do
      it 'normalizes nested hashes recursively' do
        input = {
          'columns' => [
            { 'one' => 1 },
            { 'one' => 1, 'two' => { 'three' => 3 } }
          ]
        }
        result = Toon.encode(input, normalize_on: 'columns')
        # First hash should get 'two' key with nested hash containing 'three' => nil
        # Second hash keeps its structure
        # Both should now have same structure, so use list format (nested objects)
        expect(result).to eq(
          "columns[2]:\n" \
          "  - one: 1\n" \
          "    two:\n" \
          "      three: null\n" \
          "  - one: 1\n" \
          "    two:\n" \
          "      three: 3"
        )
      end

      it 'normalizes deeply nested structures' do
        input = {
          'items' => [
            { 'a' => { 'b' => { 'c' => 1 } } },
            { 'a' => { 'b' => {} } },
            { 'a' => {} }
          ]
        }
        result = Toon.encode(input, normalize_on: 'items')
        # All should have a.b.c structure
        expect(result).to eq(
          "items[3]:\n" \
          "  - a:\n" \
          "      b:\n" \
          "        c: 1\n" \
          "  - a:\n" \
          "      b:\n" \
          "        c: null\n" \
          "  - a:\n" \
          "      b:\n" \
          "        c: null"
        )
      end

      it 'normalizes mixed nested and flat keys' do
        input = {
          'data' => [
            { 'id' => 1, 'meta' => { 'name' => 'test' } },
            { 'id' => 2 },
            { 'meta' => { 'name' => 'test2', 'value' => 42 } }
          ]
        }
        result = Toon.encode(input, normalize_on: 'data')
        # All should have 'id' and 'meta' with nested 'name' and 'value'
        expect(result).to eq(
          "data[3]:\n" \
          "  - id: 1\n" \
          "    meta:\n" \
          "      name: test\n" \
          "      value: null\n" \
          "  - id: 2\n" \
          "    meta:\n" \
          "      name: null\n" \
          "      value: null\n" \
          "  - id: null\n" \
          "    meta:\n" \
          "      name: test2\n" \
          "      value: 42"
        )
      end

      it 'handles multiple levels of nesting' do
        input = {
          'records' => [
            { 'level1' => { 'level2' => { 'level3' => 'deep' } } },
            { 'level1' => { 'level2' => { 'other' => 'value' } } }
          ]
        }
        result = Toon.encode(input, normalize_on: 'records')
        # Both should have level1.level2.level3 and level1.level2.other
        expect(result).to eq(
          "records[2]:\n" \
          "  - level1:\n" \
          "      level2:\n" \
          "        level3: deep\n" \
          "        other: null\n" \
          "  - level1:\n" \
          "      level2:\n" \
          "        level3: null\n" \
          "        other: value"
        )
      end
    end

    describe 'edge cases' do
      it 'handles arrays with non-hash elements gracefully' do
        input = { 'mixed' => [1, 'string', { 'key' => 'value' }] }
        result = Toon.encode(input, normalize_on: 'mixed')
        # Should not crash, returns array as-is (not all hashes)
        expect(result).to eq(
          "mixed[3]:\n" \
          "  - 1\n" \
          "  - string\n" \
          "  - key: value"
        )
      end

      it 'handles input that is not a hash' do
        input = [{ 'one' => 1 }, { 'one' => 1, 'two' => 2 }]
        result = Toon.encode(input, normalize_on: 'columns')
        # Should not crash, just ignore normalize_on for non-hash input
        expect(result).to eq(
          "[2]:\n" \
          "  - one: 1\n" \
          "  - one: 1\n" \
          "    two: 2"
        )
      end

      it 'preserves existing keys with nil values' do
        input = {
          'data' => [
            { 'a' => nil, 'b' => 1 },
            { 'a' => 2 }
          ]
        }
        result = Toon.encode(input, normalize_on: 'data')
        expect(result).to eq("data[2]{a,b}:\n  null,1\n  2,null")
      end

      it 'handles hashes with all same keys (no normalization needed)' do
        input = {
          'items' => [
            { 'id' => 1, 'name' => 'first' },
            { 'id' => 2, 'name' => 'second' }
          ]
        }
        result = Toon.encode(input, normalize_on: 'items')
        # Should still work, just no changes needed
        expect(result).to eq("items[2]{id,name}:\n  1,first\n  2,second")
      end
    end

    describe 'integration with other options' do
      it 'works with delimiter option' do
        input = { 'columns' => [{ 'one' => 1 }, { 'one' => 1, 'two' => 2 }] }
        result = Toon.encode(input, normalize_on: 'columns', delimiter: '|')
        expect(result).to eq("columns[2|]{one|two}:\n  1|null\n  1|2")
      end

      it 'works with length_marker option' do
        input = { 'columns' => [{ 'one' => 1 }, { 'one' => 1, 'two' => 2 }] }
        result = Toon.encode(input, normalize_on: 'columns', length_marker: '#')
        expect(result).to eq("columns[#2]{one,two}:\n  1,null\n  1,2")
      end

      it 'works with indent option' do
        input = { 'columns' => [{ 'one' => 1 }, { 'one' => 1, 'two' => 2 }] }
        result = Toon.encode(input, normalize_on: 'columns', indent: 4)
        expect(result).to eq("columns[2]{one,two}:\n    1,null\n    1,2")
      end

      it 'works with all options combined' do
        input = { 'columns' => [{ 'one' => 1 }, { 'one' => 1, 'two' => 2 }] }
        result = Toon.encode(input, normalize_on: 'columns', delimiter: '|', length_marker: '#', indent: 4)
        expect(result).to eq("columns[#2|]{one|two}:\n    1|null\n    1|2")
      end
    end
  end

  describe 'stringify_on option' do
    describe 'basic stringification' do
      it 'stringifies arrays in hash values' do
        input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{one,two}:\n  1,\"[2]\"")
      end

      it 'stringifies hashes in hash values' do
        input = { 'columns' => [{ 'one' => 1, 'three' => { 'three' => 3 } }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{one,three}:\n  1,\"{\\\"three\\\"=>3}\"")
      end

      it 'stringifies both arrays and hashes' do
        input = { 'columns' => [{ 'one' => 1, 'two' => [2], 'three' => { 'three' => 3 } }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{one,two,three}:\n  1,\"[2]\",\"{\\\"three\\\"=>3}\"")
      end

      it 'handles multiple hashes in the array' do
        input = {
          'columns' => [
            { 'id' => 1, 'data' => [1, 2, 3] },
            { 'id' => 2, 'data' => { 'a' => 1 } }
          ]
        }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[2]{id,data}:\n  1,\"[1, 2, 3]\"\n  2,\"{\\\"a\\\"=>1}\"")
      end
    end

    describe 'primitive preservation' do
      it 'keeps strings as-is' do
        input = { 'columns' => [{ 'id' => 1, 'name' => 'test' }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{id,name}:\n  1,test")
      end

      it 'keeps numbers as-is' do
        input = { 'columns' => [{ 'int' => 42, 'float' => 3.14, 'negative' => -7 }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{int,float,negative}:\n  42,3.14,-7")
      end

      it 'keeps booleans as-is' do
        input = { 'columns' => [{ 'yes' => true, 'no' => false }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{yes,no}:\n  true,false")
      end

      it 'keeps nil as-is' do
        input = { 'columns' => [{ 'id' => 1, 'value' => nil }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{id,value}:\n  1,null")
      end

      it 'handles mix of primitives and non-primitives' do
        input = {
          'columns' => [{
            'str' => 'text',
            'num' => 123,
            'bool' => true,
            'nil' => nil,
            'arr' => [1, 2],
            'hash' => { 'key' => 'val' }
          }]
        }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{str,num,bool,nil,arr,hash}:\n  text,123,true,null,\"[1, 2]\",\"{\\\"key\\\"=>\\\"val\\\"}\"")
      end
    end

    describe 'edge cases' do
      it 'does not modify input when stringify_on is nil' do
        input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
        result = Toon.encode(input, stringify_on: nil)
        # Without stringify_on, nested array causes list format
        expect(result).to eq(
          "columns[1]:\n" \
          "  - one: 1\n" \
          "    two[1]: 2"
        )
      end

      it 'does not modify input when stringify_on key does not exist' do
        input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
        result = Toon.encode(input, stringify_on: 'nonexistent')
        # Should behave as normal without stringification
        expect(result).to eq(
          "columns[1]:\n" \
          "  - one: 1\n" \
          "    two[1]: 2"
        )
      end

      it 'handles empty arrays' do
        input = { 'columns' => [] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq('columns[0]:')
      end

      it 'handles single hash in array' do
        input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{one,two}:\n  1,\"[2]\"")
      end

      it 'handles empty arrays as values' do
        input = { 'columns' => [{ 'id' => 1, 'data' => [] }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{id,data}:\n  1,\"[]\"")
      end

      it 'handles empty hashes as values' do
        input = { 'columns' => [{ 'id' => 1, 'data' => {} }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{id,data}:\n  1,\"{}\"")
      end

      it 'handles nested arrays' do
        input = { 'columns' => [{ 'id' => 1, 'matrix' => [[1, 2], [3, 4]] }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{id,matrix}:\n  1,\"[[1, 2], [3, 4]]\"")
      end

      it 'handles nested hashes' do
        input = { 'columns' => [{ 'id' => 1, 'nested' => { 'a' => { 'b' => 2 } } }] }
        result = Toon.encode(input, stringify_on: 'columns')
        expect(result).to eq("columns[1]{id,nested}:\n  1,\"{\\\"a\\\"=>{\\\"b\\\"=>2}}\"")
      end

      it 'handles arrays with non-hash elements gracefully' do
        input = { 'mixed' => [1, 'string', { 'key' => [1, 2] }] }
        result = Toon.encode(input, stringify_on: 'mixed')
        # Should not crash, returns array as-is (not all hashes)
        expect(result).to eq(
          "mixed[3]:\n" \
          "  - 1\n" \
          "  - string\n" \
          "  - key[2]: 1,2"
        )
      end

      it 'handles input that is not a hash' do
        input = [{ 'one' => 1, 'two' => [2] }]
        result = Toon.encode(input, stringify_on: 'columns')
        # Should not crash, just ignore stringify_on for non-hash input
        expect(result).to eq(
          "[1]:\n" \
          "  - one: 1\n" \
          "    two[1]: 2"
        )
      end
    end

    describe 'integration with normalize_on' do
      it 'applies normalize_on first, then stringify_on' do
        input = {
          'columns' => [
            { 'one' => 1 },
            { 'one' => 1, 'two' => [2] }
          ]
        }
        result = Toon.encode(input, normalize_on: 'columns', stringify_on: 'columns')
        # After normalize: both have 'one' and 'two' keys (first gets two: nil)
        # After stringify: [2] becomes "[2]", nil stays nil
        expect(result).to eq("columns[2]{one,two}:\n  1,null\n  1,\"[2]\"")
      end

      it 'works with both options on same key' do
        input = {
          'data' => [
            { 'id' => 1, 'values' => [1, 2, 3] },
            { 'values' => [4, 5] },
            { 'id' => 3, 'meta' => { 'key' => 'value' } }
          ]
        }
        result = Toon.encode(input, normalize_on: 'data', stringify_on: 'data')
        # After normalize: all have id, values, meta
        # After stringify: arrays and hashes become strings, primitives stay
        expect(result).to eq(
          "data[3]{id,values,meta}:\n" \
          "  1,\"[1, 2, 3]\",null\n" \
          "  null,\"[4, 5]\",null\n" \
          "  3,null,\"{\\\"key\\\"=>\\\"value\\\"}\""
        )
      end

      it 'preserves execution order (normalize then stringify)' do
        input = {
          'columns' => [
            { 'one' => 1, 'two' => { 'a' => 1 } },
            { 'two' => { 'a' => 1, 'b' => 2 } }
          ]
        }
        result = Toon.encode(input, normalize_on: 'columns', stringify_on: 'columns')
        # After normalize: both have 'one' and 'two' keys
        # After stringify: the hash values get stringified
        expect(result).to eq(
          "columns[2]{one,two}:\n" \
          "  1,\"{\\\"a\\\"=>1, \\\"b\\\"=>nil}\"\n" \
          "  null,\"{\\\"a\\\"=>1, \\\"b\\\"=>2}\""
        )
      end
    end

    describe 'integration with other options' do
      it 'works with delimiter option' do
        input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
        result = Toon.encode(input, stringify_on: 'columns', delimiter: '|')
        expect(result).to eq("columns[1|]{one|two}:\n  1|\"[2]\"")
      end

      it 'works with length_marker option' do
        input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
        result = Toon.encode(input, stringify_on: 'columns', length_marker: '#')
        expect(result).to eq("columns[#1]{one,two}:\n  1,\"[2]\"")
      end

      it 'works with indent option' do
        input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
        result = Toon.encode(input, stringify_on: 'columns', indent: 4)
        expect(result).to eq("columns[1]{one,two}:\n    1,\"[2]\"")
      end

      it 'works with all options combined' do
        input = {
          'columns' => [
            { 'one' => 1 },
            { 'one' => 1, 'two' => [2], 'three' => { 'x' => 3 } }
          ]
        }
        result = Toon.encode(
          input,
          normalize_on: 'columns',
          stringify_on: 'columns',
          delimiter: '|',
          length_marker: '#',
          indent: 4
        )
        # After normalize: first hash gets three: {"x" => nil} (nested hash structure)
        # After stringify: {"x" => nil} becomes string "{\"x\"=>nil}"
        expect(result).to eq(
          "columns[#2|]{one|two|three}:\n" \
          "    1|null|\"{\\\"x\\\"=>nil}\"\n" \
          "    1|\"[2]\"|\"{\\\"x\\\"=>3}\""
        )
      end
    end
  end

  describe 'flatten_on option' do
    describe 'basic flattening' do
      it 'flattens simple nested hash' do
        input = { 'items' => [{ 'one' => { 'two' => 2 } }] }
        result = Toon.encode(input, flatten_on: 'items')
        expect(result).to eq("items[1]{one.two}:\n  2")
      end

      it 'flattens multiple levels of nesting' do
        input = { 'items' => [{ 'a' => { 'b' => { 'c' => 3 } } }] }
        result = Toon.encode(input, flatten_on: 'items')
        expect(result).to eq("items[1]{a.b.c}:\n  3")
      end

      it 'flattens mixed hash and non-hash values' do
        input = { 'items' => [{ 'one' => 1, 'two' => { 'three' => 3 } }] }
        result = Toon.encode(input, flatten_on: 'items')
        expect(result).to eq("items[1]{one,two.three}:\n  1,3")
      end

      it 'does not flatten array values' do
        input = { 'items' => [{ 'one' => [1, 2], 'two' => { 'three' => 3 } }] }
        result = Toon.encode(input, flatten_on: 'items')
        # Arrays remain as-is, only hashes are flattened
        expect(result).to eq(
          "items[1]:\n" \
          "  - one[2]: 1,2\n" \
          "    two.three: 3"
        )
      end

      it 'flattens multiple hashes in array' do
        input = {
          'items' => [
            { 'a' => { 'b' => 1 } },
            { 'a' => { 'b' => 2 } }
          ]
        }
        result = Toon.encode(input, flatten_on: 'items')
        expect(result).to eq("items[2]{a.b}:\n  1\n  2")
      end

      it 'handles empty nested hashes' do
        input = { 'items' => [{ 'one' => {} }] }
        result = Toon.encode(input, flatten_on: 'items')
        # Empty hash produces no keys, resulting in empty hash which uses list format
        expect(result).to eq("items[1]:\n  -")
      end

      it 'handles deeply nested structures' do
        input = {
          'items' => [{
            'level1' => {
              'level2' => {
                'level3' => {
                  'level4' => 'deep'
                }
              }
            }
          }]
        }
        result = Toon.encode(input, flatten_on: 'items')
        expect(result).to eq("items[1]{level1.level2.level3.level4}:\n  deep")
      end

      it 'flattens complex nested structure' do
        input = {
          'items' => [{
            'id' => 1,
            'meta' => {
              'author' => 'Alice',
              'tags' => {
                'primary' => 'tech',
                'secondary' => 'ai'
              }
            }
          }]
        }
        result = Toon.encode(input, flatten_on: 'items')
        expect(result).to eq("items[1]{id,meta.author,meta.tags.primary,meta.tags.secondary}:\n  1,Alice,tech,ai")
      end
    end

    describe 'edge cases' do
      it 'does not modify input when flatten_on is nil' do
        input = { 'items' => [{ 'one' => { 'two' => 2 } }] }
        result = Toon.encode(input, flatten_on: nil)
        # Without flatten_on, nested hash causes list format
        expect(result).to eq(
          "items[1]:\n" \
          "  - one:\n" \
          "      two: 2"
        )
      end

      it 'does not modify input when flatten_on key does not exist' do
        input = { 'items' => [{ 'one' => { 'two' => 2 } }] }
        result = Toon.encode(input, flatten_on: 'nonexistent')
        # Should behave as normal without flattening
        expect(result).to eq(
          "items[1]:\n" \
          "  - one:\n" \
          "      two: 2"
        )
      end

      it 'handles empty arrays' do
        input = { 'items' => [] }
        result = Toon.encode(input, flatten_on: 'items')
        expect(result).to eq('items[0]:')
      end

      it 'handles single hash in array' do
        input = { 'items' => [{ 'one' => { 'two' => 2 } }] }
        result = Toon.encode(input, flatten_on: 'items')
        expect(result).to eq("items[1]{one.two}:\n  2")
      end

      it 'handles arrays with non-hash elements gracefully' do
        input = { 'mixed' => [1, 'string', { 'key' => { 'nested' => 'value' } }] }
        result = Toon.encode(input, flatten_on: 'mixed')
        # Should not crash, returns array as-is (not all hashes, so no flattening)
        expect(result).to eq(
          "mixed[3]:\n" \
          "  - 1\n" \
          "  - string\n" \
          "  - key:\n" \
          "      nested: value"
        )
      end

      it 'handles input that is not a hash' do
        input = [{ 'one' => { 'two' => 2 } }]
        result = Toon.encode(input, flatten_on: 'items')
        # Should not crash, just ignore flatten_on for non-hash input
        expect(result).to eq(
          "[1]:\n" \
          "  - one:\n" \
          "      two: 2"
        )
      end

      it 'handles nil values in nested hashes' do
        input = { 'items' => [{ 'a' => { 'b' => nil } }] }
        result = Toon.encode(input, flatten_on: 'items')
        expect(result).to eq("items[1]{a.b}:\n  null")
      end

      it 'handles mixed types as nested values' do
        input = {
          'items' => [{
            'a' => { 'b' => 1 },
            'c' => 'string',
            'd' => true,
            'e' => nil
          }]
        }
        result = Toon.encode(input, flatten_on: 'items')
        expect(result).to eq("items[1]{a.b,c,d,e}:\n  1,string,true,null")
      end
    end

    describe 'integration with normalize_on' do
      it 'applies normalize_on first, then flatten_on' do
        input = {
          'items' => [
            { 'one' => { 'two' => 2 } },
            { 'one' => { 'two' => 2, 'three' => 3 } }
          ]
        }
        result = Toon.encode(input, normalize_on: 'items', flatten_on: 'items')
        # After normalize: both have same nested structure
        # After flatten: nested keys become flat
        expect(result).to eq("items[2]{one.two,one.three}:\n  2,null\n  2,3")
      end

      it 'works with both options on same key' do
        input = {
          'data' => [
            { 'id' => 1, 'meta' => { 'name' => 'Alice' } },
            { 'meta' => { 'name' => 'Bob', 'age' => 30 } },
            { 'id' => 3 }
          ]
        }
        result = Toon.encode(input, normalize_on: 'data', flatten_on: 'data')
        # After normalize: all have id and meta with same nested keys
        # After flatten: meta.name and meta.age become flat keys
        expect(result).to eq(
          "data[3]{id,meta.name,meta.age}:\n" \
          "  1,Alice,null\n" \
          "  null,Bob,30\n" \
          "  3,null,null"
        )
      end
    end

    describe 'integration with stringify_on' do
      it 'applies flatten_on first, then stringify_on' do
        input = {
          'items' => [{
            'one' => { 'two' => [1, 2, 3] }
          }]
        }
        result = Toon.encode(input, flatten_on: 'items', stringify_on: 'items')
        # After flatten: one.two becomes a key with array value
        # After stringify: array becomes string
        expect(result).to eq("items[1]{one.two}:\n  \"[1, 2, 3]\"")
      end

      it 'preserves primitives after flattening and stringifies arrays' do
        input = {
          'items' => [{
            'a' => { 'b' => 1 },
            'c' => [2, 3]
          }]
        }
        result = Toon.encode(input, flatten_on: 'items', stringify_on: 'items')
        # After flatten: a.b => 1, c => [2,3]
        # After stringify: primitive stays, array becomes string
        expect(result).to eq("items[1]{a.b,c}:\n  1,\"[2, 3]\"")
      end
    end

    describe 'integration with all three options' do
      it 'applies normalize, flatten, then stringify in correct order' do
        input = {
          'items' => [
            { 'one' => { 'two' => [1, 2] } },
            { 'one' => { 'two' => [3, 4], 'three' => { 'four' => 5 } } }
          ]
        }
        result = Toon.encode(
          input,
          normalize_on: 'items',
          flatten_on: 'items',
          stringify_on: 'items'
        )
        # After normalize: both have one.two and one.three.four structure
        # After flatten: one.two and one.three.four become flat keys
        # After stringify: arrays become strings, primitives stay
        expect(result).to eq(
          "items[2]{one.two,one.three.four}:\n" \
          "  \"[1, 2]\",null\n" \
          "  \"[3, 4]\",5"
        )
      end

      it 'handles complex nested structures with all options' do
        input = {
          'data' => [
            { 'id' => 1, 'meta' => { 'tags' => ['a', 'b'] } },
            { 'meta' => { 'tags' => ['c'], 'priority' => 2 } }
          ]
        }
        result = Toon.encode(
          input,
          normalize_on: 'data',
          flatten_on: 'data',
          stringify_on: 'data'
        )
        # After normalize: both have id, meta.tags, meta.priority
        # After flatten: meta.tags and meta.priority become flat keys
        # After stringify: arrays become strings
        expect(result).to eq(
          "data[2]{id,meta.tags,meta.priority}:\n" \
          "  1,\"[\\\"a\\\", \\\"b\\\"]\",null\n" \
          "  null,\"[\\\"c\\\"]\",2"
        )
      end
    end

    describe 'integration with other options' do
      it 'works with delimiter option' do
        input = { 'items' => [{ 'one' => { 'two' => 2 } }] }
        result = Toon.encode(input, flatten_on: 'items', delimiter: '|')
        expect(result).to eq("items[1|]{one.two}:\n  2")
      end

      it 'works with length_marker option' do
        input = { 'items' => [{ 'one' => { 'two' => 2 } }] }
        result = Toon.encode(input, flatten_on: 'items', length_marker: '#')
        expect(result).to eq("items[#1]{one.two}:\n  2")
      end

      it 'works with indent option' do
        input = { 'items' => [{ 'one' => { 'two' => 2 } }] }
        result = Toon.encode(input, flatten_on: 'items', indent: 4)
        expect(result).to eq("items[1]{one.two}:\n    2")
      end

      it 'works with all options combined' do
        input = {
          'items' => [
            { 'a' => { 'b' => 1 } },
            { 'a' => { 'b' => 2, 'c' => [3, 4] } }
          ]
        }
        result = Toon.encode(
          input,
          normalize_on: 'items',
          flatten_on: 'items',
          stringify_on: 'items',
          delimiter: '|',
          length_marker: '#',
          indent: 4
        )
        # After normalize: both have a.b and a.c structure
        # After flatten: a.b and a.c become flat keys
        # After stringify: array becomes string
        expect(result).to eq(
          "items[#2|]{a.b|a.c}:\n" \
          "    1|null\n" \
          "    2|\"[3, 4]\""
        )
      end
    end
  end
end
