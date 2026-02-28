package ex.ss.lib.base

import android.content.Context
import androidx.annotation.ColorInt
import ex.ss.lib.base.extension.DimensExtension
import ex.ss.lib.base.view.ImmersiveNavigationBarHolder
import ex.ss.lib.base.view.ImmersiveStatusBarHolder

object SSBase {
    fun initialize(context: Context) {
        DimensExtension.init(context)
    }

    @Deprecated(
        "please use setImmersiveBar", ReplaceWith(
            "setImmersiveBar(immersive)", "ex.ss.lib.base.SSBase.setImmersiveBar"
        )
    )
    fun setImmersiveStatusBar(immersive: Boolean) {
        setImmersiveBar(immersive)
    }

    fun setImmersiveBar(immersive: Boolean) {
        setStatusBarImmersive(immersive)
        setNavigationBarImmersive(immersive)
    }


    fun setStatusBarImmersive(immersive: Boolean) {
        ImmersiveStatusBarHolder.ImmersiveBar = immersive
    }


    fun setNavigationBarImmersive(immersive: Boolean) {
        ImmersiveNavigationBarHolder.ImmersiveBar = immersive
    }

    fun setImmersiveBarColor(@ColorInt color: Int) {
        setImmersiveStatusBarColor(color)
        setImmersiveNavigationBarColor(color)
    }

    fun setImmersiveStatusBarColor(@ColorInt color: Int) {
        ImmersiveStatusBarHolder.BarColor = color
    }

    fun setImmersiveNavigationBarColor(@ColorInt color: Int) {
        ImmersiveNavigationBarHolder.BarColor = color
    }

}