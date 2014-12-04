Swift-URITemplate
====

** Xcode 6.1 REQUIRED **

Swift-URITemplate is a Swift implementation of URI Template -- 
[RFC6570](http://tools.ietf.org/html/rfc6570), can expand templates up to and 
including Level 4 in that specification.

In case you are not familiar with URI Template, it's an utility which can be used 
to expand a string with values, like what `printf` does, but for URL. For example, 
if you give Swift-URITemplate a string `http://www.example.com/foo{?query,number}` 
(the format part), and a dictionary `{"query": "mycelium", "number": 100}` 
(the value part), Swift-URITemplate will return you an expanded URL 
`http://www.example.com/foo?query=mycelium&number=100`. More information can be 
found in [RFC 6570](http://tools.ietf.org/html/rfc6570), or you can go check the 
tests in [URITemplateRFCTests.json](https://github.com/weipin/Swift-URITemplate/blob/master/tests/URITemplateRFCTests.json).

Swift-URITemplate was initially developed for HTTP library [Cycles](http://www.swift-cycles.org).


Installation
====
Swift-URITemplate hasn't been packaged as a framework for now. You will have to 
add the [single source file](https://github.com/weipin/Swift-URITemplate/blob/master/source/URITemplate.swift) 
to your own project to use Swift-URITemplate.


Expand URI Template
====

To expand an URI Template, you use function `ExpandURITemplate`:

```
public func ExpandURITemplate(template: String, values: AnyObject) -> String
```

The parameter `template` is the template to expand. The parameter `values` is the 
object which provides values for expanding. 

Values
----

- The `values` can be a Swift Dictionary:

```
var URLString = ExpandURITemplate("http://www.example.com/foo{?query,number}",
                                  ["query": "mycelium", "number": "100"])
println("\(URLString)") // http://www.example.com/foo?query=mycelium&number=100
```

- Or a NSDictionary:

```
var URLString = ExpandURITemplate("http://www.example.com/foo{?query,number}",
                                  NSDictionary(objects: ["mycelium", "100"], forKeys: ["query", "number"]))
println("\(URLString)") // http://www.example.com/foo?query=mycelium&number=100
```

- Or any object responses to the method `objectForKey`.


Value types
----

- The objects that `values` provides can be string:

```
var URLString = ExpandURITemplate("http://www.example.com/foo{?query,number}",
                                  NSDictionary(objects: ["mycelium", "100"], forKeys: ["query", "number"]))
println("\(URLString)") // http://www.example.com/foo?query=mycelium&number=100
```

- Or number (see the value of key `mycelium` in the code snippet below):

```
var URLString = ExpandURITemplate("http://www.example.com/foo{?query,number}",
                                  NSDictionary(objects: ["mycelium", 100], forKeys: ["query", "number"]))
println("\(URLString)") // http://www.example.com/foo?query=mycelium&number=100
```

- Or any object responses to the method `stringValue`.


Support
====
Please use the [issues system](https://github.com/weipin/Swift-URITemplate/issues). 
We look forward to hearing your thoughts on the project.


License
====
Swift-URITemplate is released under the MIT license. See [LICENSE.md](https://github.com/weipin/Swift-URITemplate/blob/master/LICENSE).
