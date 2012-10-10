//
//  CMRThreadUserStatusMask.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//


// 一時フラグは保存しない
#define TUS_FL_NOT_TEMP_MASK	(0xfffff)		// 20bit
#define TUS_VERSION_1_0_MAGIC	(0x800000U)		// version 1.0 magic number
#define TUS_VERSION_MASK		(0x3800000)		// 24-26 (3bit)

#define TUS_FL_USER_USED_MASK	(0x3f)			// 6bit
#define TUS_ASCII_ART_FLAG		(0x40)			// 7

// available in BathyScaphe 1.2 and later
#define TUS_DAT_OCHI_FLAG		(0x80)
#define TUS_MARKED_FLAG			(0x01)

// Available in BathyScaphe 2.0 and later.
// 下位 4 bit をラベルに使用
// 最下位 1 bit でラベルの有無
// 残り 3 bit の組み合わせでラベルを決定
#define TUS_LABELED_FLAG        TUS_MARKED_FLAG
#define TUS_LABEL_0             TUS_MARKED_FLAG // 以前の「フラグ付き」はラベル 1 に移行
#define TUS_LABEL_1             (0x03)
#define TUS_LABEL_2             (0x05)
#define TUS_LABEL_3             (0x07)
#define TUS_LABEL_4             (0x09)
#define TUS_LABEL_5             (0x0B)
#define TUS_LABEL_6             (0x0D)
#define TUS_LABEL_MASK          (0x0F)
