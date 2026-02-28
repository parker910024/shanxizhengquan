package com.proxy.base.ui.main

import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentManager
import androidx.lifecycle.Lifecycle
import androidx.viewpager2.adapter.FragmentStateAdapter

class MainPageAdapter(
    fragmentManager: FragmentManager,
    lifecycle: Lifecycle,
    private val fragmentInvoker: () -> List<Fragment>
) : FragmentStateAdapter(fragmentManager, lifecycle) {

    private val fragments by lazy { fragmentInvoker.invoke() }

    override fun getItemCount(): Int = fragments.size

    override fun createFragment(position: Int): Fragment {
        return fragments[position]
    }
}