package com.yanshu.app.ui.web

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import androidx.core.os.bundleOf
import com.yanshu.app.databinding.ActivityWebBinding
import ex.ss.lib.base.extension.viewBinding

class SimpleWebActivityArgs(
    val title: String,
    val url: String,
    val menu: String = "",
    val menuIcon: Int = 0,
    val menuKey: String = ""
) {
    companion object {
        private const val WEB_ARGS_TITLE = "web_args_title"
        private const val WEB_ARGS_URL = "web_args_url"
        private const val WEB_ARGS_MENU = "web_args_menu"
        private const val WEB_ARGS_MENU_ICON = "web_args_menu_icon"
        private const val WEB_ARGS_MENU_KEY = "web_args_menu_key"

        fun fromBundle(intent: Intent): SimpleWebActivityArgs {
            val bundle = intent.extras ?: bundleOf()
            val title = bundle.getString(WEB_ARGS_TITLE, "")
            val url = bundle.getString(WEB_ARGS_URL, "")
            val menu = bundle.getString(WEB_ARGS_MENU, "")
            val menuIcon = bundle.getInt(WEB_ARGS_MENU_ICON, 0)
            val menuKey = bundle.getString(WEB_ARGS_MENU_KEY, "")
            return SimpleWebActivityArgs(title, url, menu, menuIcon, menuKey)
        }
    }

    fun toBundle(): Bundle {
        return bundleOf(
            WEB_ARGS_TITLE to title,
            WEB_ARGS_URL to url,
            WEB_ARGS_MENU to menu,
            WEB_ARGS_MENU_ICON to menuIcon,
            WEB_ARGS_MENU_KEY to menuKey,
        )
    }
}

class SimpleWebActivity : BaseWebActivity() {

    override val binding: ActivityWebBinding by viewBinding()
    private val args by lazy { SimpleWebActivityArgs.fromBundle(intent) }

    companion object {
        private val menuClick = mutableMapOf<String, (String) -> Unit>()

        fun registerMenuClick(menuKey: String, onClick: (String) -> Unit) {
            menuClick[menuKey] = onClick
        }

        fun start(context: Context, title: String, url: String) {
            val intent = Intent(context, SimpleWebActivity::class.java).apply {
                putExtras(SimpleWebActivityArgs(title, url).toBundle())
            }
            context.startActivity(intent)
        }
    }

    override fun initView() {
        binding.titleBar.tvBack.setOnClickListener { finish() }
        binding.titleBar.tvTitle.text = if (args.title.isNotEmpty()) args.title else "详情"
        binding.titleBar.tvMenu.visibility = View.GONE

        if (args.menu.isNotEmpty()) {
            binding.titleBar.tvMenu.visibility = View.VISIBLE
            binding.titleBar.tvMenu.text = args.menu
        }

        if (args.menuIcon != 0) {
            binding.titleBar.tvMenu.visibility = View.VISIBLE
            binding.titleBar.tvMenu.setCompoundDrawablesWithIntrinsicBounds(
                args.menuIcon, 0, 0, 0
            )
        }

        if (args.menuKey.isNotEmpty()) {
            binding.titleBar.tvMenu.setOnClickListener {
                menuClick[args.menuKey]?.invoke(args.menuKey)
            }
        }

        super.initView()
    }

    override fun initData() {
        // 可以在这里加载数据
    }

    override fun getUrl(): String = args.url
}
