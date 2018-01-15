/* 
Copyright (c) 2018 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct Likes : Codable {
	let count : Int?
	let user_likes : Int?
	let can_like : Int?
	let can_publish : Int?

	enum CodingKeys: String, CodingKey {

		case count = "count"
		case user_likes = "user_likes"
		case can_like = "can_like"
		case can_publish = "can_publish"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
        //let test = try! values.decode(Int.self, forKey: .count)
		count = try values.decodeIfPresent(Int.self, forKey: .count)
		user_likes = try values.decodeIfPresent(Int.self, forKey: .user_likes)
		can_like = try values.decodeIfPresent(Int.self, forKey: .can_like)
		can_publish = try values.decodeIfPresent(Int.self, forKey: .can_publish)
	}

}