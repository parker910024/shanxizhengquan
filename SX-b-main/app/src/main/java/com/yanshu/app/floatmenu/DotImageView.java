/*
 * Copyright (c) 2016, Shanghai YUEWEN Information Technology Co., Ltd.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 *  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *  Neither the name of Shanghai YUEWEN Information Technology Co., Ltd. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY SHANGHAI YUEWEN INFORMATION TECHNOLOGY CO., LTD. AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
package com.yanshu.app.floatmenu;

import android.animation.Animator;
import android.animation.ValueAnimator;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Camera;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.RectF;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.view.View;
import android.view.animation.LinearInterpolator;

import androidx.annotation.Nullable;

/**
 * 00%=FF（不透明）    5%=F2    10%=E5    15%=D8    20%=CC    25%=BF    30%=B2    35%=A5    40%=99    45%=8c    50%=7F
 * 55%=72    60%=66    65%=59    70%=4c    75%=3F    80%=33    85%=21    90%=19    95%=0c    100%=00（全透明）
 */
public class DotImageView extends View {
    public static final int NORMAL = 0;
    public static final int HIDE_LEFT = 1;
    public static final int HIDE_RIGHT = 2;
    private Paint mPaint;
    private Paint mPaintBg;
    private String dotNum = null;
    private float mAlphaValue;
    private float mRotateValue = 1f;
    private boolean inited = false;

    private Bitmap mBitmap;
    private final int mLogoBackgroundRadius = dip2px(30);
    private final int mLogoWhiteRadius = dip2px(26);
    private final int mRedPointRadiusWithNum = dip2px(6);
    private final int mRedPointRadius = dip2px(3);
    private final int mRedPointOffset = dip2px(10);

    private boolean isDrag = false;
    private float scaleOffset;
    private ValueAnimator mDragValueAnimator;
    private LinearInterpolator mLinearInterpolator = new LinearInterpolator();
    public boolean mDrawDarkBg = true;
    private static final float hideOffset = 0.4f;
    private Camera mCamera;

    private boolean mDrawNum = false;
    private int mStatus = NORMAL;
    private int mLastStatus = mStatus;
    private Matrix mMatrix;
    private boolean mIsResetPosition;
    private int mBgColor = 0x99000000;

    public void setBgColor(int bgColor) {
        mBgColor = bgColor;
    }

    public void setDrawNum(boolean drawNum) {
        this.mDrawNum = drawNum;
    }

    public void setDrawDarkBg(boolean drawDarkBg) {
        mDrawDarkBg = drawDarkBg;
        invalidate();
    }

    public int getStatus() {
        return mStatus;
    }

    public void setStatus(int status) {
        this.mStatus = status;
        isDrag = false;
        if (this.mStatus != NORMAL) {
            setDrawNum(mDrawNum);
            this.mDrawDarkBg = true;
        }
        invalidate();
    }

    public void setBitmap(Bitmap bitmap) {
        mBitmap = bitmap;
    }

    public DotImageView(Context context, Bitmap bitmap) {
        super(context);
        this.mBitmap = bitmap;
        init();
    }

    public DotImageView(Context context) {
        super(context);
        init();
    }

    public DotImageView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public DotImageView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        mPaint = new Paint();
        mPaint.setAntiAlias(true);
        mPaint.setFilterBitmap(true);
        mPaint.setDither(true);
        mPaint.setTextSize(sp2px(10));
        mPaint.setStyle(Paint.Style.FILL);

        mPaintBg = new Paint();
        mPaintBg.setAntiAlias(true);
        mPaintBg.setStyle(Paint.Style.FILL);
        mPaintBg.setColor(mBgColor);

        mCamera = new Camera();
        mMatrix = new Matrix();
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        int wh = mLogoBackgroundRadius * 2;
        setMeasuredDimension(wh, wh);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float centerX = getWidth() / 2;
        float centerY = getHeight() / 2;
        canvas.save();
        mCamera.save();
        if (mStatus == NORMAL) {
            if (mLastStatus != NORMAL) {
                canvas.restore();
                mCamera.restore();
            }
            if (isDrag) {
                canvas.scale((scaleOffset + 1f), (scaleOffset + 1f), getWidth() / 2, getHeight() / 2);
                if (mIsResetPosition) {
                    mCamera.save();
                    mCamera.rotateX(720 * scaleOffset);
                    mCamera.getMatrix(mMatrix);
                    mMatrix.preTranslate(-getWidth() / 2, -getHeight() / 2);
                    mMatrix.postTranslate(getWidth() / 2, getHeight() / 2);
                    canvas.concat(mMatrix);
                    mCamera.restore();
                } else {
                    canvas.rotate(60 * mRotateValue, getWidth() / 2, getHeight() / 2);
                }
            }
        } else if (mStatus == HIDE_LEFT) {
            canvas.translate(-getWidth() * hideOffset, 0);
            canvas.rotate(-45, getWidth() / 2, getHeight() / 2);
        } else if (mStatus == HIDE_RIGHT) {
            canvas.translate(getWidth() * hideOffset, 0);
            canvas.rotate(45, getWidth() / 2, getHeight() / 2);
        }
        canvas.save();
        if (!isDrag) {
            if (mDrawDarkBg) {
                mPaintBg.setColor(mBgColor);
                canvas.drawCircle(centerX, centerY, mLogoBackgroundRadius, mPaintBg);
                mPaint.setColor(0x99ffffff);
            } else {
                mPaint.setColor(0xFFFFFFFF);
            }
            if (mAlphaValue != 0) {
                mPaint.setAlpha((int) (mAlphaValue * 255));
            }
            canvas.drawCircle(centerX, centerY, mLogoWhiteRadius, mPaint);
        }
        canvas.restore();

        if (mBitmap != null && !mBitmap.isRecycled()) {
            mPaint.setColor(0xFFFFFFFF);
            mPaint.setFilterBitmap(true);
            mPaint.setAntiAlias(true);
            float targetSize = mLogoWhiteRadius * 2 * 0.85f;
            float scaleX = targetSize / mBitmap.getWidth();
            float scaleY = targetSize / mBitmap.getHeight();
            float scale = Math.min(scaleX, scaleY);
            float scaledWidth = mBitmap.getWidth() * scale;
            float scaledHeight = mBitmap.getHeight() * scale;
            Matrix drawMatrix = new Matrix();
            drawMatrix.postScale(scale, scale);
            drawMatrix.postTranslate(
                    centerX - scaledWidth / 2,
                    centerY - scaledHeight / 2
            );
            canvas.drawBitmap(mBitmap, drawMatrix, mPaint);
        }

        if (!TextUtils.isEmpty(dotNum)) {
            int readPointRadius = mDrawNum ? mRedPointRadiusWithNum : mRedPointRadius;
            mPaint.setColor(Color.RED);
            if (mStatus == HIDE_LEFT) {
                canvas.drawCircle(centerX + mRedPointOffset, centerY - mRedPointOffset, readPointRadius, mPaint);
                if (mDrawNum) {
                    mPaint.setColor(Color.WHITE);
                    canvas.drawText(dotNum, centerX + mRedPointOffset - getTextWidth(dotNum, mPaint) / 2, centerY - mRedPointOffset + getTextHeight(dotNum, mPaint) / 2, mPaint);
                }
            } else if (mStatus == HIDE_RIGHT) {
                canvas.drawCircle(centerX - mRedPointOffset, centerY - mRedPointOffset, readPointRadius, mPaint);
                if (mDrawNum) {
                    mPaint.setColor(Color.WHITE);
                    canvas.drawText(dotNum, centerX - mRedPointOffset - getTextWidth(dotNum, mPaint) / 2, centerY - mRedPointOffset + getTextHeight(dotNum, mPaint) / 2, mPaint);
                }
            } else {
                if (mLastStatus == HIDE_LEFT) {
                    canvas.drawCircle(centerX + mRedPointOffset, centerY - mRedPointOffset, readPointRadius, mPaint);
                    if (mDrawNum) {
                        mPaint.setColor(Color.WHITE);
                        canvas.drawText(dotNum, centerX + mRedPointOffset - getTextWidth(dotNum, mPaint) / 2, centerY - mRedPointOffset + getTextHeight(dotNum, mPaint) / 2, mPaint);
                    }
                } else if (mLastStatus == HIDE_RIGHT) {
                    canvas.drawCircle(centerX - mRedPointOffset, centerY - mRedPointOffset, readPointRadius, mPaint);
                    if (mDrawNum) {
                        mPaint.setColor(Color.WHITE);
                        canvas.drawText(dotNum, centerX - mRedPointOffset - getTextWidth(dotNum, mPaint) / 2, centerY - mRedPointOffset + getTextHeight(dotNum, mPaint) / 2, mPaint);
                    }
                }
            }
        }
        mLastStatus = mStatus;
    }

    public void setDotNum(int num, Animator.AnimatorListener l) {
        if (!inited) {
            startAnim(num, l);
        } else {
            refreshDot(num);
        }
    }

    private void refreshDot(int num) {
        if (num > 0) {
            String dotNumTmp = String.valueOf(num);
            if (!TextUtils.equals(dotNum, dotNumTmp)) {
                dotNum = dotNumTmp;
                invalidate();
            }
        } else {
            dotNum = null;
        }
    }

    public void startAnim(final int num, Animator.AnimatorListener l) {
        ValueAnimator valueAnimator = ValueAnimator.ofFloat(1.f, 0.6f, 1f, 0.6f);
        valueAnimator.setInterpolator(mLinearInterpolator);
        valueAnimator.setDuration(3000);
        valueAnimator.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
            @Override
            public void onAnimationUpdate(ValueAnimator animation) {
                mAlphaValue = (float) animation.getAnimatedValue();
                invalidate();
            }
        });
        valueAnimator.addListener(l);
        valueAnimator.addListener(new Animator.AnimatorListener() {
            @Override
            public void onAnimationStart(Animator animation) {}
            @Override
            public void onAnimationEnd(Animator animation) {
                inited = true;
                refreshDot(num);
                mAlphaValue = 0;
            }
            @Override
            public void onAnimationCancel(Animator animation) {
                mAlphaValue = 0;
            }
            @Override
            public void onAnimationRepeat(Animator animation) {}
        });
        valueAnimator.start();
    }

    public void setDrag(boolean drag, float offset, boolean isResetPosition) {
        isDrag = drag;
        this.mIsResetPosition = isResetPosition;
        if (offset > 0 && offset != this.scaleOffset) {
            this.scaleOffset = offset;
        }
        if (isDrag && mStatus == NORMAL) {
            if (mDragValueAnimator != null) {
                if (mDragValueAnimator.isRunning()) return;
            }
            mDragValueAnimator = ValueAnimator.ofFloat(0, 6f, 12f, 0f);
            mDragValueAnimator.setInterpolator(mLinearInterpolator);
            mDragValueAnimator.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
                @Override
                public void onAnimationUpdate(ValueAnimator animation) {
                    mRotateValue = (float) animation.getAnimatedValue();
                    invalidate();
                }
            });
            mDragValueAnimator.addListener(new Animator.AnimatorListener() {
                @Override
                public void onAnimationStart(Animator animation) {}
                @Override
                public void onAnimationEnd(Animator animation) {
                    isDrag = false;
                    mIsResetPosition = false;
                }
                @Override
                public void onAnimationCancel(Animator animation) {}
                @Override
                public void onAnimationRepeat(Animator animation) {}
            });
            mDragValueAnimator.setDuration(1000);
            mDragValueAnimator.start();
        }
    }

    private int dip2px(float dipValue) {
        final float scale = getContext().getResources().getDisplayMetrics().density;
        return (int) (dipValue * scale + 0.5f);
    }

    private int sp2px(float spValue) {
        final float fontScale = getContext().getResources().getDisplayMetrics().scaledDensity;
        return (int) (spValue * fontScale + 0.5f);
    }

    private float getTextHeight(String text, Paint paint) {
        Rect rect = new Rect();
        paint.getTextBounds(text, 0, text.length(), rect);
        return rect.height() / 1.1f;
    }

    private float getTextWidth(String text, Paint paint) {
        return paint.measureText(text);
    }
}
