assert 304..343
311..343 binaryExpr 311..343 left(binaryExpr 311..332 left(binaryExpr 311..317 left(unaryExpr 311..313 operand(negate literalExpr 312..313))))
311..332 binaryExpr 311..332 left(binaryExpr 311..317 left(unaryExpr 311..313 operand(negate literalExpr 312..313)))
311..317 binaryExpr 311..317 left(unaryExpr 311..313 operand(negate literalExpr 312..313))
311..313 unaryExpr 311..313 operand(negate literalExpr 312..313)
316..317 literalExpr 316..317
321..332 unaryExpr 321..332 operand(notKeyword parenExpr 322..332 inner(binaryExpr 323..331 left(memberExpr 323..326 member(325..326))))
323..331 binaryExpr 323..331 left(memberExpr 323..326 member(325..326))
323..326 memberExpr 323..326 member(325..326)
323..324 nameExpr 323..324
330..331 literalExpr 330..331
336..343 binaryExpr 336..343 left(unaryExpr 336..338 operand(complement literalExpr 337..338))
336..338 unaryExpr 336..338 operand(complement literalExpr 337..338)
337..338 literalExpr 337..338
342..343 literalExpr 342..343
assert 344..364
351..364 binaryExpr 351..364 left(parenExpr 351..359 inner(binaryExpr 352..358 left(nameExpr 352..353)))
352..358 binaryExpr 352..358 left(nameExpr 352..353)
352..353 nameExpr 352..353
357..358 literalExpr 357..358
363..364 literalExpr 363..364
assert 365..383
372..383 inExpr 372..383
372..375 memberExpr 372..375 member(374..375)
372..373 nameExpr 372..373
379..383 rangeExpr 379..383
379..380 literalExpr 379..380
382..383 literalExpr 382..383
assert 384..413
391..413 binaryExpr 391..413 left(parenExpr 391..408 inner(conditionalExpr 392..407 condition(binaryExpr 392..399 left(memberExpr 392..395 member(394..395)))))
392..407 conditionalExpr 392..407 condition(binaryExpr 392..399 left(memberExpr 392..395 member(394..395)))
392..399 binaryExpr 392..399 left(memberExpr 392..395 member(394..395))
392..395 memberExpr 392..395 member(394..395)
392..393 nameExpr 392..393
398..399 literalExpr 398..399
402..403 literalExpr 402..403
406..407 literalExpr 406..407
412..413 literalExpr 412..413
assert 414..434
421..434 binaryExpr 421..434 left(callExpr 421..429 callee(nameExpr 421..424))
421..429 callExpr 421..429 callee(nameExpr 421..424)
425..428 memberExpr 425..428 member(427..428)
425..426 nameExpr 425..426
433..434 literalExpr 433..434
assert 435..464
442..464 binaryExpr 442..464 left(binaryExpr 442..459 left(indexExpr 442..447 target(nameExpr 442..444)))
442..459 binaryExpr 442..459 left(indexExpr 442..447 target(nameExpr 442..444))
442..447 indexExpr 442..447 target(nameExpr 442..444)
442..447 indexExpr 442..447 target(nameExpr 442..444)
442..444 nameExpr 442..444
445..446 literalExpr 445..446
450..459 memberExpr 450..459 member(453..459)
450..452 nameExpr 450..452
463..464 literalExpr 463..464
assert 465..500
472..500 binaryExpr 472..500 left(interpolatedExpr 472..491)
472..491 interpolatedExpr 472..491
475..478 memberExpr 475..478 member(477..478)
475..476 nameExpr 475..476
481..489 callExpr 481..489 callee(nameExpr 481..486)
487..488 literalExpr 487..488
495..500 literalExpr 495..500
assert 501..532
508..532 binaryExpr 508..532 left(memberExpr 508..527 member(526..527))
508..527 memberExpr 508..527 member(526..527)
509..524 withExpr 509..524
509..510 nameExpr 509..510
521..522 literalExpr 521..522
531..532 literalExpr 531..532
assert 533..564
540..564 binaryExpr 540..564 left(memberExpr 540..549 member(546..549))
540..549 memberExpr 540..549 member(546..549)
553..564 memberExpr 553..564 member(559..564)
assert 565..601
572..601 binaryExpr 572..601 left(callExpr 572..596 callee(nameExpr 572..577))
572..596 callExpr 572..596 callee(nameExpr 572..577)
578..579 literalExpr 578..579
585..595 lambdaExpr 585..595
600..601 literalExpr 600..601
assert 602..628
609..628 binaryExpr 609..628 left(memberExpr 609..623 member(617..623))
609..623 memberExpr 609..623 member(617..623)
609..616 indexExpr 609..616 target(nameExpr 609..611)
609..611 nameExpr 609..611
612..613 literalExpr 612..613
627..628 literalExpr 627..628
assert 629..675
636..675 binaryExpr 636..675 left(parenExpr 636..669 inner(switchExpr 637..668))
637..668 switchExpr 637..668
637..640 memberExpr 637..640 member(639..640)
637..638 nameExpr 637..638
650..651 -
650..651 literalExpr 650..651
655..657 literalExpr 655..657
659..660 -
664..666 literalExpr 664..666
673..675 literalExpr 673..675
assert 676..707
683..707 binaryExpr 683..707 left(parenExpr 683..702 inner(catchExpr 684..701))
684..701 catchExpr 684..701
684..693 callExpr 684..693 callee(nameExpr 684..690)
691..692 literalExpr 691..692
700..701 literalExpr 700..701
706..707 literalExpr 706..707
assert 708..733
715..733 binaryExpr 715..733 left(parenExpr 715..728 inner(binaryExpr 716..727 left(parenExpr 716..723 inner(binaryExpr 717..722 left(literalExpr 717..718)))))
716..727 binaryExpr 716..727 left(parenExpr 716..723 inner(binaryExpr 717..722 left(literalExpr 717..718)))
717..722 binaryExpr 717..722 left(literalExpr 717..718)
717..718 literalExpr 717..718
721..722 literalExpr 721..722
726..727 literalExpr 726..727
732..733 literalExpr 732..733
assert 734..765
741..765 binaryExpr 741..765 left(binaryExpr 741..757 left(memberExpr 741..752 member(746..752)))
741..757 binaryExpr 741..757 left(memberExpr 741..752 member(746..752))
741..752 memberExpr 741..752 member(746..752)
741..745 literalExpr 741..745
756..757 literalExpr 756..757
761..765 literalExpr 761..765
assert 766..812
773..812 binaryExpr 773..812 left(binaryExpr 773..800 left(memberExpr 773..795 member(791..795)))
773..800 binaryExpr 773..800 left(memberExpr 773..795 member(791..795))
773..795 memberExpr 773..795 member(791..795)
773..790 tupleExpr 773..790
780..781 literalExpr 780..781
788..789 literalExpr 788..789
799..800 literalExpr 799..800
804..812 isExpr 804..812 value(nameExpr 804..805)
804..805 nameExpr 804..805
809..812 -