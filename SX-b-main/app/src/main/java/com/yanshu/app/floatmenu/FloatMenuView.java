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
import android.animation.ObjectAnimator;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PointF;
import android.graphics.Rect;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;

import java.util.ArrayList;
import java.util.List;

public class FloatMenuView extends View {
    public static final int STATUS_LEFT = 3;
    public static final int STATUS_RIGHT = 4;

    private int mStatus = STATUS_RIGHT;
    private Paint mPaint;
    private int mBackgroundColor = 0x00FFFFFF;
    private int mMenuBackgroundColor = -1;
    private RectF mBgRect;
    private int mItemWidth = dip2px(45);
    private int mItemHeight = dip2px(45);
    private int mItemSpacing = dip2px(10);
    private int mItemLeft = 0;
    private int mCorner = dip2px(2);
    private int mRadius = dip2px(4);
    private final int mRedPointRadiuWithNoNum = dip2px(3);
    private int mFontSizePointNum = sp2px(10);
    private int mFontSizeTitle = sp2px(12);
    private float mFirstItemTop;
    private boolean mDrawNum = false;
    private boolean circleBg = false;

    private List<FloatItem> mItemList = new ArrayList<>();
    private List<RectF> mItemRectList = new ArrayList<>();
    private OnMenuClickListener mOnMenuClickListener;
    private ObjectAnimator mAlphaAnim;

    public void setItemList(List<FloatItem> itemList) {
        mItemList = itemList;
    }

    public void drawNum(boolean drawNum) {
        mDrawNum = drawNum;
    }

    public void setCircleBg(boolean circleBg) {
        this.circleBg = circleBg;
    }

    public void setMenuBackgroundColor(int mMenuBackgroundColor) {
        this.mMenuBackgroundColor = mMenuBackgroundColor;
    }

    public void setBackgroundColor(int BackgroundColor) {
        this.mBackgroundColor = BackgroundColor;
    }

    public FloatMenuView(Context context) {
        super(context);
    }

    public FloatMenuView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public FloatMenuView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public FloatMenuView(Context baseContext, int status) {
        super(baseContext);
        mStatus = status;
        int screenWidth = getResources().getDisplayMetrics().widthPixels;
        int screenHeight = getResources().getDisplayMetrics().heightPixels;
        mBgRect = new RectF(0, 0, screenWidth, screenHeight);
        setBackgroundColor(Color.TRANSPARENT);
        initView();
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        int totalWidth = mItemWidth * mItemList.size() + mItemSpacing * (mItemList.size() > 0 ? mItemList.size() - 1 : 0);
        setMeasuredDimension(totalWidth, mItemHeight);
    }

    private void initView() {
        mPaint = new Paint();
        mPaint.setAntiAlias(true);
        mPaint.setStyle(Paint.Style.FILL);
        mPaint.setTextSize(sp2px(16));

        mAlphaAnim = ObjectAnimator.ofFloat(this, "alpha", 1.0f, 0f);
        mAlphaAnim.setDuration(50);
        mAlphaAnim.addListener(new MyAnimListener() {
            @Override
            public void onAnimationEnd(Animator animation) {
                if (mOnMenuClickListener != null) {
                    removeView();
                    mOnMenuClickListener.dismiss();
                }
            }
        });

        mFirstItemTop = 0;
        mItemLeft = 0;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        switch (mStatus) {
            case STATUS_LEFT:
            case STATUS_RIGHT:
                drawFloatLeftItem(canvas);
                break;
        }
    }

    private void drawFloatLeftItem(Canvas canvas) {
        mItemRectList.clear();
        for (int i = 0; i < mItemList.size(); i++) {
            canvas.save();
            float itemLeft = mItemLeft + i * (mItemWidth + mItemSpacing);
            float itemRight = itemLeft + mItemWidth;
            float cx = itemLeft + mItemWidth / 2;
            float cy = mFirstItemTop + mItemHeight / 2;
            float radius = mItemWidth / 2;

            mPaint.setColor(mItemList.get(i).bgColor);
            canvas.drawCircle(cx, cy, radius, mPaint);

            mItemRectList.add(new RectF(itemLeft, mFirstItemTop, itemRight, mFirstItemTop + mItemHeight));
            drawIconTitleDot(canvas, i);
        }
        canvas.restore();
    }

    private void drawIconTitleDot(Canvas canvas, int position) {
        FloatItem floatItem = mItemList.get(position);
        float itemLeft = mItemLeft + position * (mItemWidth + mItemSpacing);
        float centerX = itemLeft + mItemWidth / 2;
        float centerY = mFirstItemTop + mItemHeight / 2;

        mPaint.setColor(floatItem.titleColor);
        mPaint.setTextSize(mFontSizeTitle);
        float textY = centerY + getTextHeight(floatItem.getTitle(), mPaint) / 3;
        canvas.drawText(floatItem.title, centerX - getTextWidth(floatItem.getTitle(), mPaint) / 2, textY, mPaint);

        drawIndicatorsInCircle(canvas, centerX, centerY, textY, floatItem);
    }

    private void drawIndicatorsInCircle(Canvas canvas, float centerX, float centerY, float textBaseline, FloatItem item) {
        if (!item.hasNodeFailureIndicator && !item.hasNonWhitelistIndicator) {
            return;
        }
        float textWidth = getTextWidth(item.title, mPaint);
        float underlineWidth = textWidth * 0.7f;
        float underlineHeight = dip2px(2);
        float cornerRadius = dip2px(1);
        int nodeFailureColor = Color.RED;
        int nonWhitelistColor = Color.BLUE;
        float startY = textBaseline + dip2px(2);

        Paint underlinePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        underlinePaint.setStyle(Paint.Style.FILL);

        if (item.hasNodeFailureIndicator) {
            underlinePaint.setColor(nodeFailureColor);
            RectF rect1 = new RectF(
                    centerX - underlineWidth / 2, startY,
                    centerX + underlineWidth / 2, startY + underlineHeight
            );
            canvas.drawRoundRect(rect1, cornerRadius, cornerRadius, underlinePaint);
        }
        if (item.hasNonWhitelistIndicator) {
            underlinePaint.setColor(nonWhitelistColor);
            float secondLineY = item.hasNodeFailureIndicator
                    ? startY + underlineHeight + dip2px(2)
                    : startY;
            RectF rect2 = new RectF(
                    centerX - underlineWidth / 2, secondLineY,
                    centerX + underlineWidth / 2, secondLineY + underlineHeight
            );
            canvas.drawRoundRect(rect2, cornerRadius, cornerRadius, underlinePaint);
        }
    }

    public void startAnim() {
        if (mItemList.size() == 0) return;
        invalidate();
    }

    public void dismiss() {
        if (!mAlphaAnim.isRunning()) {
            mAlphaAnim.start();
        }
    }

    private void removeView() {
        ViewGroup vg = (ViewGroup) this.getParent();
        if (vg != null) {
            vg.removeView(this);
        }
    }

    @Override
    protected void onWindowVisibilityChanged(int visibility) {
        if (visibility == GONE) {
            if (mOnMenuClickListener != null) {
                mOnMenuClickListener.dismiss();
            }
        }
        super.onWindowVisibilityChanged(visibility);
    }

    public void setOnMenuClickListener(OnMenuClickListener onMenuClickListener) {
        this.mOnMenuClickListener = onMenuClickListener;
    }

    public interface OnMenuClickListener {
        void onItemClick(int position, String title);
        void dismiss();
    }

    private abstract class MyAnimListener implements Animator.AnimatorListener {
        @Override
        public void onAnimationStart(Animator animation) {}
        @Override
        public void onAnimationCancel(Animator animation) {}
        @Override
        public void onAnimationRepeat(Animator animation) {}
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                for (int i = 0; i < mItemRectList.size(); i++) {
                    if (mOnMenuClickListener != null && isPointInRect(new PointF(event.getX(), event.getY()), mItemRectList.get(i))) {
                        mOnMenuClickListener.onItemClick(i, mItemList.get(i).title);
                        return true;
                    }
                }
                dismiss();
        }
        return false;
    }

    private boolean isPointInRect(PointF pointF, RectF targetRect) {
        return pointF.x >= targetRect.left && pointF.x <= targetRect.right && pointF.y >= targetRect.top && pointF.y <= targetRect.bottom;
    }

    public static class Builder {
        private Context mActivity;
        private List<FloatItem> mFloatItems = new ArrayList<>();
        private int mBgColor = Color.TRANSPARENT;
        private int mStatus = STATUS_LEFT;
        private boolean cicleBg = false;
        private int mMenuBackgroundColor = -1;
        private boolean mDrawNum = false;

        public Builder drawNum(boolean drawNum) {
            mDrawNum = drawNum;
            return this;
        }

        public Builder setMenuBackgroundColor(int mMenuBackgroundColor) {
            this.mMenuBackgroundColor = mMenuBackgroundColor;
            return this;
        }

        public Builder setCicleBg(boolean cicleBg) {
            this.cicleBg = cicleBg;
            return this;
        }

        public Builder setStatus(int status) {
            mStatus = status;
            return this;
        }

        public Builder setFloatItems(List<FloatItem> floatItems) {
            this.mFloatItems = floatItems;
            return this;
        }

        public Builder(Context activity) {
            mActivity = activity;
        }

        public Builder addItem(FloatItem floatItem) {
            mFloatItems.add(floatItem);
            return this;
        }

        public Builder addItems(List<FloatItem> list) {
            mFloatItems.addAll(list);
            return this;
        }

        public Builder setBackgroundColor(int color) {
            mBgColor = color;
            return this;
        }

        public FloatMenuView create() {
            FloatMenuView floatMenuView = new FloatMenuView(mActivity, mStatus);
            floatMenuView.setItemList(mFloatItems);
            floatMenuView.setBackgroundColor(mBgColor);
            floatMenuView.setCircleBg(cicleBg);
            floatMenuView.startAnim();
            floatMenuView.drawNum(mDrawNum);
            floatMenuView.setMenuBackgroundColor(mMenuBackgroundColor);
            return floatMenuView;
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
