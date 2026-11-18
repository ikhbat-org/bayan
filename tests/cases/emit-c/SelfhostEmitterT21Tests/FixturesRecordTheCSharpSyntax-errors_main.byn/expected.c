assert 160..178
167..178 binaryExpr 167..178 left(memberExpr 167..173 member(169..173))
assert 179..199
186..199 nameExpr 186..199
assert 200..219
207..219 binaryExpr 207..219 left(binaryExpr 207..214 left(literalExpr 207..208))
assert 220..239
227..239 binaryExpr 227..239 left(callExpr 227..234 callee(nameExpr 227..229))
assert 240..274
247..274 binaryExpr 247..274 left(binaryExpr 247..270 left(literalExpr 247..266))
assert 275..291
282..291 binaryExpr 282..291 left(memberExpr 282..285 member(284..285))
assert 292..310
299..310 binaryExpr 299..310 left(indexExpr 299..305 target(nameExpr 299..300))
299..305 indexExpr 299..305 target(nameExpr 299..300)
299..300 nameExpr 299..300
301..304 literalExpr 301..304
309..310 literalExpr 309..310
assert 311..342
318..342 binaryExpr 318..342 left(binaryExpr 318..337 left(memberExpr 318..331 member(325..331)))
318..337 binaryExpr 318..337 left(memberExpr 318..331 member(325..331))
318..331 memberExpr 318..331 member(325..331)
318..324 collectionExpr 318..324
319..320 literalExpr 319..320
322..323 literalExpr 322..323
334..337 memberExpr 334..337 member(336..337)
334..335 nameExpr 334..335
341..342 literalExpr 341..342
assert 343..378
350..378 binaryExpr 350..378 left(binaryExpr 350..360 left(unaryExpr 350..355 operand(negate parenExpr 351..355 inner(unaryExpr 352..354 operand(negate literalExpr 353..354)))))
350..360 binaryExpr 350..360 left(unaryExpr 350..355 operand(negate parenExpr 351..355 inner(unaryExpr 352..354 operand(negate literalExpr 353..354))))
350..355 unaryExpr 350..355 operand(negate parenExpr 351..355 inner(unaryExpr 352..354 operand(negate literalExpr 353..354)))
352..354 unaryExpr 352..354 operand(negate literalExpr 353..354)
359..360 literalExpr 359..360
364..378 binaryExpr 364..378 left(unaryExpr 364..369 operand(notKeyword literalExpr 365..369))
364..369 unaryExpr 364..369 operand(notKeyword literalExpr 365..369)
365..369 literalExpr 365..369
373..378 literalExpr 373..378