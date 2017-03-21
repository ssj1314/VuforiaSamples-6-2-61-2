/*===============================================================================
Copyright (c) 2016 PTC Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other
countries.

@file 
    VuMarkTargetResult.h

@brief
    Header file for VuMarkTargetResult class.
===============================================================================*/
#ifndef _VUFORIA_VUMARKTARGETRESULT_H_
#define _VUFORIA_VUMARKTARGETRESULT_H_

// Include files
#include <Vuforia/ObjectTargetResult.h>
#include <Vuforia/VuMarkTarget.h>

namespace Vuforia
{

/// Result for a VuMarkTarget. 
/**
 *  The same VuMarkTarget can have multiple physical instances on screen
 *  simultaneously. In this case each appearance has its own VuMarkTargetResult,
 *  pointing to the same VuMarkTarget with the same instance ID.
 同样的vumark目标可以有多个实例同时在屏幕的物理。在这种情况下，每个外观有自己的vumark目标结果，指向同一目标vumark实例ID。
 */
class VUFORIA_API VuMarkTargetResult : public ObjectTargetResult
{
public:

    /// Returns the TrackableResult class' type 返回可追踪的结果类型
    static Type getClassType();//获得类类型

    /// Returns the corresponding Trackable that this result represents
    //返回相应的跟踪，这一结果表示
    virtual const VuMarkTarget& getTrackable() const = 0;

    /// Returns a unique id for a particular VuMark result, which is consistent
    //独特的ID是返回的结果是一致的，这是一vumark
    /// frame-to-frame, while being tracked.  Note that this id is separate
    //帧到帧，同时被跟踪。请注意，这个身份证是分开的
    /// from the trackable id.
    virtual int getId() const = 0;
};
//
} // namespace Vuforia

#endif //_VUFORIA_VUMARKTARGETRESULT_H_
