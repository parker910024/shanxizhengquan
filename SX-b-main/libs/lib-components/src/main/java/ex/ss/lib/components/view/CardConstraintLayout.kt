package ex.ss.lib.components.view

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Rect
import android.graphics.drawable.Drawable
import android.os.Build
import android.util.AttributeSet
import android.view.View
import androidx.annotation.ColorInt
import androidx.annotation.Px
import androidx.constraintlayout.widget.ConstraintLayout
import ex.ss.lib.components.R
import ex.ss.lib.components.view.card.CardViewApi17Impl
import ex.ss.lib.components.view.card.CardViewApi21Impl
import ex.ss.lib.components.view.card.CardViewBaseImpl
import ex.ss.lib.components.view.card.CardViewDelegate
import ex.ss.lib.components.view.card.CardViewImpl


open class CardConstraintLayout @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0, defStyleRes: Int = 0,
) : ConstraintLayout(context, attrs, defStyleAttr, defStyleRes) {

    private val mCardViewDelegate: CardViewDelegate = object : CardViewDelegate {
        private var mCardBackground: Drawable? = null

        override fun setCardBackground(drawable: Drawable?) {
            mCardBackground = drawable
            background = drawable
        }

        override fun getUseCompatPadding(): Boolean {
            return this@CardConstraintLayout.getUseCompatPadding()
        }

        override fun getPreventCornerOverlap(): Boolean {
            return this@CardConstraintLayout.getPreventCornerOverlap()
        }

        override fun setShadowPadding(left: Int, top: Int, right: Int, bottom: Int) {
            mShadowBounds[left, top, right] = bottom
            super@CardConstraintLayout.setPadding(
                left + mContentPadding.left, top + mContentPadding.top,
                right + mContentPadding.right, bottom + mContentPadding.bottom
            )
        }

        override fun setMinWidthHeightInternal(width: Int, height: Int) {
            if (width > mUserSetMinWidth) {
                super@CardConstraintLayout.setMinimumWidth(width)
            }
            if (height > mUserSetMinHeight) {
                super@CardConstraintLayout.setMinimumHeight(height)
            }
        }

        override fun getCardBackground(): Drawable? {
            return mCardBackground
        }

        override fun getCardView(): View? {
            return this@CardConstraintLayout
        }
    }


    private val COLOR_BACKGROUND_ATTR = intArrayOf(android.R.attr.colorBackground)
    private val IMPL: CardViewImpl by lazy {
        if (Build.VERSION.SDK_INT >= 21) {
            CardViewApi21Impl();
        } else if (Build.VERSION.SDK_INT >= 17) {
            CardViewApi17Impl();
        } else {
            CardViewBaseImpl();
        }
    }

    private var mCompatPadding = false

    private var mPreventCornerOverlap = false


    /**
     * CardView requires to have a particular minimum size to draw shadows before API 21. If
     * developer also sets min width/height, they might be overridden.
     *
     * CardView works around this issue by recording user given parameters and using an internal
     * method to set them.
     */
    var mUserSetMinWidth = 0

    var mUserSetMinHeight = 0

    val mContentPadding = Rect()

    val mShadowBounds = Rect()

    init {
        IMPL.initStatic()
        val a =
            context.obtainStyledAttributes(
                attrs,
                R.styleable.CardConstraintLayout,
                defStyleAttr,
                defStyleRes
            )
        val backgroundColor: ColorStateList? =
            if (a.hasValue(R.styleable.CardConstraintLayout_cardBackgroundColor)) {
                a.getColorStateList(R.styleable.CardConstraintLayout_cardBackgroundColor)
            } else {
                // There isn't one set, so we'll compute one based on the theme
                val aa = getContext().obtainStyledAttributes(COLOR_BACKGROUND_ATTR)
                val themeColorBackground = aa.getColor(0, 0)
                aa.recycle()

                // If the theme colorBackground is light, use our own light color, otherwise dark
                val hsv = FloatArray(3)
                Color.colorToHSV(themeColorBackground, hsv)
                /**
                 *     <color name="cardview_dark_background">#FF424242</color>
                 *     <color name="cardview_light_background">#FFFFFFFF</color>
                 */
                ColorStateList.valueOf(
                    if (hsv[2] > 0.5f) Color.parseColor("#FFFFFFFF") else Color.parseColor("#FF424242")
                )
            }
        val radius = a.getDimension(R.styleable.CardConstraintLayout_cardCornerRadius, 0f)
        val elevation = a.getDimension(R.styleable.CardConstraintLayout_cardElevation, 0f)
        var maxElevation = a.getDimension(R.styleable.CardConstraintLayout_cardMaxElevation, 0f)
        mCompatPadding = a.getBoolean(R.styleable.CardConstraintLayout_cardUseCompatPadding, false)
        mPreventCornerOverlap =
            a.getBoolean(R.styleable.CardConstraintLayout_cardPreventCornerOverlap, true)
        val defaultPadding =
            a.getDimensionPixelSize(R.styleable.CardConstraintLayout_contentPadding, 0)
        mContentPadding.left = a.getDimensionPixelSize(
            R.styleable.CardConstraintLayout_contentPaddingLeft,
            defaultPadding
        )
        mContentPadding.top = a.getDimensionPixelSize(
            R.styleable.CardConstraintLayout_contentPaddingTop,
            defaultPadding
        )
        mContentPadding.right = a.getDimensionPixelSize(
            R.styleable.CardConstraintLayout_contentPaddingRight,
            defaultPadding
        )
        mContentPadding.bottom = a.getDimensionPixelSize(
            R.styleable.CardConstraintLayout_contentPaddingBottom,
            defaultPadding
        )
        if (elevation > maxElevation) {
            maxElevation = elevation
        }
        mUserSetMinWidth =
            a.getDimensionPixelSize(R.styleable.CardConstraintLayout_android_minWidth, 0)
        mUserSetMinHeight =
            a.getDimensionPixelSize(R.styleable.CardConstraintLayout_android_minHeight, 0)
        a.recycle()

        IMPL.initialize(
            mCardViewDelegate, context, backgroundColor, radius,
            elevation, maxElevation
        )
    }

    override fun setPadding(left: Int, top: Int, right: Int, bottom: Int) {
        // NO OP
    }

    override fun setPaddingRelative(start: Int, top: Int, end: Int, bottom: Int) {
        // NO OP
    }

    /**
     * Returns whether CardView will add inner padding on platforms Lollipop and after.
     *
     * @return `true` if CardView adds inner padding on platforms Lollipop and after to
     * have same dimensions with platforms before Lollipop.
     */
    fun getUseCompatPadding(): Boolean {
        return mCompatPadding
    }

    /**
     * CardView adds additional padding to draw shadows on platforms before Lollipop.
     *
     *
     * This may cause Cards to have different sizes between Lollipop and before Lollipop. If you
     * need to align CardView with other Views, you may need api version specific dimension
     * resources to account for the changes.
     * As an alternative, you can set this flag to `true` and CardView will add the same
     * padding values on platforms Lollipop and after.
     *
     *
     * Since setting this flag to true adds unnecessary gaps in the UI, default value is
     * `false`.
     *
     * @param useCompatPadding `true>` if CardView should add padding for the shadows on
     * platforms Lollipop and above.
     * @attr ref androidx.cardview.R.styleable#CardView_cardUseCompatPadding
     */
    fun setUseCompatPadding(useCompatPadding: Boolean) {
        if (mCompatPadding != useCompatPadding) {
            mCompatPadding = useCompatPadding
            IMPL.onCompatPaddingChanged(mCardViewDelegate)
        }
    }

    /**
     * Sets the padding between the Card's edges and the children of CardView.
     *
     *
     * Depending on platform version or [.getUseCompatPadding] settings, CardView may
     * update these values before calling [android.view.View.setPadding].
     *
     * @param left   The left padding in pixels
     * @param top    The top padding in pixels
     * @param right  The right padding in pixels
     * @param bottom The bottom padding in pixels
     * @attr ref androidx.cardview.R.styleable#CardView_contentPadding
     * @attr ref androidx.cardview.R.styleable#CardView_contentPaddingLeft
     * @attr ref androidx.cardview.R.styleable#CardView_contentPaddingTop
     * @attr ref androidx.cardview.R.styleable#CardView_contentPaddingRight
     * @attr ref androidx.cardview.R.styleable#CardView_contentPaddingBottom
     */
    fun setContentPadding(@Px left: Int, @Px top: Int, @Px right: Int, @Px bottom: Int) {
        mContentPadding[left, top, right] = bottom
        IMPL.updatePadding(mCardViewDelegate)
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        var widthMeasureSpec = widthMeasureSpec
        var heightMeasureSpec = heightMeasureSpec
        if (IMPL !is CardViewApi21Impl) {
            val widthMode = MeasureSpec.getMode(widthMeasureSpec)
            when (widthMode) {
                MeasureSpec.EXACTLY, MeasureSpec.AT_MOST -> {
                    val minWidth =
                        Math.ceil(IMPL.getMinWidth(mCardViewDelegate).toDouble()).toInt()
                    widthMeasureSpec = MeasureSpec.makeMeasureSpec(
                        Math.max(
                            minWidth,
                            MeasureSpec.getSize(widthMeasureSpec)
                        ), widthMode
                    )
                }

                MeasureSpec.UNSPECIFIED -> {}
            }
            val heightMode = MeasureSpec.getMode(heightMeasureSpec)
            when (heightMode) {
                MeasureSpec.EXACTLY, MeasureSpec.AT_MOST -> {
                    val minHeight =
                        Math.ceil(IMPL.getMinHeight(mCardViewDelegate).toDouble()).toInt()
                    heightMeasureSpec = MeasureSpec.makeMeasureSpec(
                        Math.max(
                            minHeight,
                            MeasureSpec.getSize(heightMeasureSpec)
                        ), heightMode
                    )
                }

                MeasureSpec.UNSPECIFIED -> {}
            }
            super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        } else {
            super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        }
    }

    override fun setMinimumWidth(minWidth: Int) {
        mUserSetMinWidth = minWidth
        super.setMinimumWidth(minWidth)
    }

    override fun setMinimumHeight(minHeight: Int) {
        mUserSetMinHeight = minHeight
        super.setMinimumHeight(minHeight)
    }

    /**
     * Updates the background color of the CardView
     *
     * @param color The new color to set for the card background
     * @attr ref androidx.cardview.R.styleable#CardView_cardBackgroundColor
     */
    fun setCardBackgroundColor(@ColorInt color: Int) {
        IMPL.setBackgroundColor(mCardViewDelegate, ColorStateList.valueOf(color))
    }

    /**
     * Updates the background ColorStateList of the CardView
     *
     * @param color The new ColorStateList to set for the card background
     * @attr ref androidx.cardview.R.styleable#CardView_cardBackgroundColor
     */
    fun setCardBackgroundColor(color: ColorStateList?) {
        IMPL.setBackgroundColor(mCardViewDelegate, color)
    }

    /**
     * Returns the background color state list of the CardView.
     *
     * @return The background color state list of the CardView.
     */
    fun getCardBackgroundColor(): ColorStateList {
        return IMPL.getBackgroundColor(mCardViewDelegate)
    }

    /**
     * Returns the inner padding after the Card's left edge
     *
     * @return the inner padding after the Card's left edge
     */
    @Px
    fun getContentPaddingLeft(): Int {
        return mContentPadding.left
    }

    /**
     * Returns the inner padding before the Card's right edge
     *
     * @return the inner padding before the Card's right edge
     */
    @Px
    fun getContentPaddingRight(): Int {
        return mContentPadding.right
    }

    /**
     * Returns the inner padding after the Card's top edge
     *
     * @return the inner padding after the Card's top edge
     */
    @Px
    fun getContentPaddingTop(): Int {
        return mContentPadding.top
    }

    /**
     * Returns the inner padding before the Card's bottom edge
     *
     * @return the inner padding before the Card's bottom edge
     */
    @Px
    fun getContentPaddingBottom(): Int {
        return mContentPadding.bottom
    }

    /**
     * Updates the corner radius of the CardView.
     *
     * @param radius The radius in pixels of the corners of the rectangle shape
     * @attr ref androidx.cardview.R.styleable#CardView_cardCornerRadius
     * @see .setRadius
     */
    fun setRadius(radius: Float) {
        IMPL.setRadius(mCardViewDelegate, radius)
    }

    /**
     * Returns the corner radius of the CardView.
     *
     * @return Corner radius of the CardView
     * @see .getRadius
     */
    fun getRadius(): Float {
        return IMPL.getRadius(mCardViewDelegate)
    }

    /**
     * Updates the backward compatible elevation of the CardView.
     *
     * @param elevation The backward compatible elevation in pixels.
     * @attr ref androidx.cardview.R.styleable#CardView_cardElevation
     * @see .getCardElevation
     * @see .setMaxCardElevation
     */
    fun setCardElevation(elevation: Float) {
        IMPL.setElevation(mCardViewDelegate, elevation)
    }

    /**
     * Returns the backward compatible elevation of the CardView.
     *
     * @return Elevation of the CardView
     * @see .setCardElevation
     * @see .getMaxCardElevation
     */
    fun getCardElevation(): Float {
        return IMPL.getElevation(mCardViewDelegate)
    }

    /**
     * Updates the backward compatible maximum elevation of the CardView.
     *
     *
     * Calling this method has no effect if device OS version is Lollipop or newer and
     * [.getUseCompatPadding] is `false`.
     *
     * @param maxElevation The backward compatible maximum elevation in pixels.
     * @attr ref androidx.cardview.R.styleable#CardView_cardMaxElevation
     * @see .setCardElevation
     * @see .getMaxCardElevation
     */
    fun setMaxCardElevation(maxElevation: Float) {
        IMPL.setMaxElevation(mCardViewDelegate, maxElevation)
    }

    /**
     * Returns the backward compatible maximum elevation of the CardView.
     *
     * @return Maximum elevation of the CardView
     * @see .setMaxCardElevation
     * @see .getCardElevation
     */
    fun getMaxCardElevation(): Float {
        return IMPL.getMaxElevation(mCardViewDelegate)
    }

    /**
     * Returns whether CardView should add extra padding to content to avoid overlaps with rounded
     * corners on pre-Lollipop platforms.
     *
     * @return True if CardView prevents overlaps with rounded corners on platforms before Lollipop.
     * Default value is `true`.
     */
    fun getPreventCornerOverlap(): Boolean {
        return mPreventCornerOverlap
    }

    /**
     * On pre-Lollipop platforms, CardView does not clip the bounds of the Card for the rounded
     * corners. Instead, it adds padding to content so that it won't overlap with the rounded
     * corners. You can disable this behavior by setting this field to `false`.
     *
     *
     * Setting this value on Lollipop and above does not have any effect unless you have enabled
     * compatibility padding.
     *
     * @param preventCornerOverlap Whether CardView should add extra padding to content to avoid
     * overlaps with the CardView corners.
     * @attr ref androidx.cardview.R.styleable#CardView_cardPreventCornerOverlap
     * @see .setUseCompatPadding
     */
    fun setPreventCornerOverlap(preventCornerOverlap: Boolean) {
        if (preventCornerOverlap != mPreventCornerOverlap) {
            mPreventCornerOverlap = preventCornerOverlap
            IMPL.onPreventCornerOverlapChanged(mCardViewDelegate)
        }
    }

}