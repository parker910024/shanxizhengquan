package com.yanshu.app.model

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.yanshu.app.data.*
import com.yanshu.app.repo.Remote
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * 统一管理线下配售（战略配售）和大宗交易（天启护盘）的业务逻辑
 */
object IPOViewModel {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // ==================== 线下配售 ====================

    private val _placementListLiveData = MutableLiveData<List<IPOItem>>()
    val placementListLiveData: LiveData<List<IPOItem>> = _placementListLiveData

    private val _myPlacementListLiveData = MutableLiveData<List<MyPlacementItem>>()
    val myPlacementListLiveData: LiveData<List<MyPlacementItem>> = _myPlacementListLiveData

    private val _placementDetailLiveData = MutableLiveData<PlacementDetailData?>()
    val placementDetailLiveData: LiveData<PlacementDetailData?> = _placementDetailLiveData

    // ==================== 新股申购记录 ====================

    private val _myIpoListLiveData = MutableLiveData<List<MyIpoItem>>()
    val myIpoListLiveData: LiveData<List<MyIpoItem>> = _myIpoListLiveData

    // ==================== 大宗交易 ====================

    private val _blockTradeListLiveData = MutableLiveData<List<BlockTradeItem>>()
    val blockTradeListLiveData: LiveData<List<BlockTradeItem>> = _blockTradeListLiveData

    /** 大宗交易余额，从列表接口获取 */
    private val _blockTradeBalanceLiveData = MutableLiveData<Double>()
    val blockTradeBalanceLiveData: LiveData<Double> = _blockTradeBalanceLiveData

    private val _blockTradeHoldingLiveData = MutableLiveData<HoldingListData?>()
    val blockTradeHoldingLiveData: LiveData<HoldingListData?> = _blockTradeHoldingLiveData

    private val _blockTradeHistoryLiveData = MutableLiveData<HoldingListData?>()
    val blockTradeHistoryLiveData: LiveData<HoldingListData?> = _blockTradeHistoryLiveData

    // ==================== 通用 ====================

    /** 操作结果: Triple(action, success, errorMsg) */
    private val _operationResult = MutableLiveData<Triple<String, Boolean, String?>>()
    val operationResult: LiveData<Triple<String, Boolean, String?>> = _operationResult

    private val _loading = MutableLiveData<Boolean>()
    val loading: LiveData<Boolean> = _loading

    // ==================== 线下配售方法 ====================

    fun loadPlacementList(page: Int = 1) {
        scope.launch {
            val response = Remote.callApi { getOfflinePlacementList(page) }
            if (response.isSuccess() && response.data != null) {
                _placementListLiveData.postValue(response.data!!.list.flatMap { it.sub_info })
            } else {
                _placementListLiveData.postValue(emptyList())
            }
        }
    }

    fun loadMyPlacementList(page: Int = 1, status: Int? = null) {
        scope.launch {
            val response = Remote.callApi { getMyPlacementList(page, status = status) }
            if (response.isSuccess() && response.data != null) {
                _myPlacementListLiveData.postValue(response.data!!.dxlog_list)
            } else {
                _myPlacementListLiveData.postValue(emptyList())
            }
        }
    }

    fun loadPlacementDetail(id: Int) {
        scope.launch {
            val response = Remote.callApi { getPlacementDetail(id) }
            _placementDetailLiveData.postValue(if (response.isSuccess()) response.data else null)
        }
    }

    fun buyPlacement(code: String, sgNums: Int, miyao: String = "") {
        scope.launch {
            _loading.postValue(true)
            val response = Remote.callApi {
                buyOfflinePlacement(
                    BuyOfflinePlacementRequest(
                        code = code,
                        sg_nums = sgNums,
                        miyao = miyao,
                    )
                )
            }
            _loading.postValue(false)
            _operationResult.postValue(Triple("buyPlacement", response.isSuccess(),
                if (!response.isSuccess()) response.failed.msg else null))
        }
    }

    // ==================== 大宗交易方法 ====================

    fun loadBlockTradeList(page: Int = 1) {
        scope.launch {
            val response = Remote.callApi { getBlockTradeList(page) }
            if (response.isSuccess() && response.data != null) {
                _blockTradeListLiveData.postValue(response.data!!.list)
                _blockTradeBalanceLiveData.postValue(response.data!!.balance)
            } else {
                _blockTradeListLiveData.postValue(emptyList())
            }
        }
    }

    fun buyBlockTrade(allcode: String, canBuy: Int, miyao: String = "") {
        scope.launch {
            _loading.postValue(true)
            val response = Remote.callApi {
                buyBlockTrade(
                    BuyBlockTradeRequest(
                        allcode = allcode,
                        canBuy = canBuy,
                        miyao = miyao,
                    )
                )
            }
            _loading.postValue(false)
            _operationResult.postValue(Triple("buyBlockTrade", response.isSuccess(),
                if (!response.isSuccess()) response.failed.msg else null))
        }
    }

    fun loadBlockTradeHolding(page: Int = 1) {
        scope.launch {
            val response = Remote.callApi { getBlockTradeHolding(page) }
            // 仅成功时更新，失败不写 null，避免已展示的列表被清空导致“数据自动消失”
            if (response.isSuccess()) {
                _blockTradeHoldingLiveData.postValue(response.data)
            }
        }
    }

    fun loadBlockTradeHistory(page: Int = 1) {
        scope.launch {
            val response = Remote.callApi { getBlockTradeHistory(page) }
            if (response.isSuccess()) {
                _blockTradeHistoryLiveData.postValue(response.data)
            }
        }
    }

    fun clearOperationResult() {
        _operationResult.value = null
    }

    fun clearPlacementDetail() {
        _placementDetailLiveData.value = null
    }

    // ==================== 新股申购记录方法 ====================

    private var myIpoListJob: Job? = null

    fun loadMyIpoList(page: Int = 1, status: Int? = null) {
        myIpoListJob?.cancel()
        myIpoListJob = scope.launch {
            val response = Remote.callApi { getMyIpoList(page, status = status) }
            if (response.isSuccess() && response.data != null) {
                _myIpoListLiveData.postValue(response.data!!.dxlog_list)
            } else {
                _myIpoListLiveData.postValue(emptyList())
            }
        }
    }

    fun renjiaoIpo(id: Int) {
        scope.launch {
            _loading.postValue(true)
            val response = Remote.callApi { renjiaoIpo(RenjiaoRequest(id = id)) }
            _loading.postValue(false)
            _operationResult.postValue(
                Triple(
                    "renjiaoIpo",
                    response.isSuccess(),
                    if (!response.isSuccess()) response.failed.msg else null,
                )
            )
        }
    }
}
