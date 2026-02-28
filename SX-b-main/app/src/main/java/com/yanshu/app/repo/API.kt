package com.yanshu.app.repo

import com.yanshu.app.data.*
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Query

interface API {

    /** 全局配置 GET /api/stock/getconfig，含 kf_url 客服地址 */
    @GET("api/stock/getconfig")
    suspend fun getConfig(): BaseResponse<AppConfigData>

    @POST("api/user/getAlicloudSTS")
    suspend fun getAlicloudSTS(): BaseResponse<AliCloudStsData>

    /** 资产（交易）GET /api/user/getUserPrice_all1（文档 2.7） */
    @GET("api/user/getUserPrice_all1")
    suspend fun getUserPrice_all1(): BaseResponse<UserPriceAll1Data>

    @GET("api/stock/info")
    suspend fun getUserInfo(): BaseResponse<UserProfileData>

    /** 资产（个人中心）GET /api/user/getUserPrice_all（文档 2.6） */
    @GET("api/user/getUserPrice_all")
    suspend fun getUserPriceAll(): BaseResponse<UserPriceAllData>

    @POST("api/user/login")
    suspend fun login(@Body request: LoginRequest): BaseResponse<LoginApiData>

    @POST("api/user/register")
    suspend fun register(@Body request: RegisterRequest): BaseResponse<LoginApiData>

    /** 验证支付密码 */
    @POST("api/user/checkOldpay")
    suspend fun checkOldpay(@Body request: CheckPayPasswordRequest): BaseResponse<Any>

    /** 修改支付密码（验证通过后仅传新密码） */
    @POST("api/user/editPass")
    suspend fun editPass(@Body request: EditPayPasswordRequest): BaseResponse<Any>

    /** 修改登录密码 */
    @POST("api/user/editPass1")
    suspend fun editPass1(@Body request: EditLoginPasswordRequest): BaseResponse<Any>

    /** 实名认证详情 GET /api/user/authenticationDetail */
    @GET("api/user/authenticationDetail")
    suspend fun getAuthenticationDetail(): BaseResponse<AuthenticationDetailData>

    /** 提交实名认证 POST /api/user/authentication */
    @POST("api/user/authentication")
    suspend fun submitAuthentication(@Body request: AuthenticationRequest): BaseResponse<Any>

    /** 银证转入/转出记录 GET api/user/capitalLog，type=0 转入 1 转出，不传查全部 */
    @GET("api/user/capitalLog")
    suspend fun getCapitalLog(@Query("type") type: Int? = null): BaseResponse<CapitalLogData>

    /** 银行卡列表 POST api/user/accountLst */
    @POST("api/user/accountLst")
    suspend fun getBankCardList(): BaseResponse<BankCardListResponse>

    /** 绑定/编辑银行卡 POST api/user/bindaccount，有 id 为编辑 */
    @POST("api/user/bindaccount")
    suspend fun bindBankCard(@Body request: BindBankCardRequest): BaseResponse<Any>

    /** 银证转出 GET api/user/applyWithdraw，参数：account_id、money、pass */
    @GET("api/user/applyWithdraw")
    suspend fun applyWithdraw(
        @Query("account_id") accountId: String,
        @Query("money") money: Double,
        @Query("pass") pass: String,
    ): BaseResponse<Any>

    /** 发起充值（银证转入）POST api/user/recharge */
    @POST("api/user/recharge")
    suspend fun recharge(@Body request: RechargeRequest): RechargeResponse

    @GET("api/index/getchargeconfignew")
    suspend fun getChargeConfigNew(): BaseResponse<ChargeConfigData>

    @GET("api/index/getyhkconfignew")
    suspend fun getYhkConfigNew(
        @Query("bankid") bankId: Int,
    ): BaseResponse<YhkConfigData>

    // ==================== Message ====================

    /** 消息列表（后端仅支持 POST：api/news/index，Body 传 page） */
    @POST("api/news/index")
    suspend fun getMessageList(@Body request: MessageListRequest): BaseResponse<MessageListData>

    /** 消息详情 GET api/news/detail */
    @GET("api/news/detail")
    suspend fun getMessageDetail(@Query("id") id: Int): BaseResponse<MessageDetailData>

    // ==================== Home news (首页新闻) ====================

    /** 新闻列表 GET api/Indexnew/getGuoneinews，type: 1国内经济 2国际经济 3证券要闻 4公司咨询 */
    @GET("api/Indexnew/getGuoneinews")
    suspend fun getGuoneinews(
        @Query("page") page: Int,
        @Query("size") size: Int,
        @Query("type") type: Int,
    ): BaseResponse<NewsListData>

    /** 新闻详情 GET api/Indexnew/getNewsssDetail */
    @GET("api/Indexnew/getNewsssDetail")
    suspend fun getNewsssDetail(@Query("news_id") newsId: String): BaseResponse<NewsDetailData>

    /** 首页轮播图 GET api/index/banner */
    @GET("api/index/banner")
    suspend fun getBanners(): BaseResponse<BannerListData>

    // ==================== Offline placement ====================

    @GET("api/subscribe/xxlst")
    suspend fun getOfflinePlacementList(
        @Query("page") page: Int = 1,
        @Query("type") type: Int = 0,
    ): BaseResponse<IPOListData>

    @POST("api/subscribe/xxadd")
    suspend fun buyOfflinePlacement(@Body request: BuyOfflinePlacementRequest): BaseResponse<Any>

    @GET("api/subscribe/getsgnewgu")
    suspend fun getMyPlacementList(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 20,
        @Query("status") status: Int? = null,
    ): BaseResponse<MyPlacementListData>

    /** 新股申购已中签未认缴数据（首页弹窗专用）GET api/stock/ballot */
    @GET("api/stock/ballot")
    suspend fun getBallotList(): BaseResponse<BallotData>

    /** 已申购新股列表（文档 3.10）GET api/subscribe/getsgnewgu0 */
    @GET("api/subscribe/getsgnewgu0")
    suspend fun getMyIpoList(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 20,
        @Query("status") status: Int? = null,
    ): BaseResponse<MyIpoListData>

    @GET("api/subscribe/lstDetail")
    suspend fun getPlacementDetail(
        @Query("id") id: Int,
    ): BaseResponse<PlacementDetailData>

    // ==================== Block trade ====================

    @GET("api/dzjy/lst")
    suspend fun getBlockTradeList(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 20,
    ): BaseResponse<BlockTradeListData>

    @POST("api/dzjy/addStrategy_zfa")
    suspend fun buyBlockTrade(@Body request: BuyBlockTradeRequest): BaseResponse<Any>

    @GET("api/dzjy/getNowWarehouse")
    suspend fun getBlockTradeHolding(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 20,
        @Query("buytype") buytype: Int = 7,
        @Query("status") status: Int = 1,
    ): BaseResponse<HoldingListData>

    @GET("api/dzjy/getNowWarehouse_lishi")
    suspend fun getBlockTradeHistory(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 20,
        @Query("buytype") buytype: Int = 7,
        @Query("status") status: Int = 2,
    ): BaseResponse<HoldingListData>

    /** 普通交易历史持仓（交易记录）GET api/deal/getNowWarehouse_lishi，buytype=1 status=2 type=2 */
    @GET("api/deal/getNowWarehouse_lishi")
    suspend fun getDealHistoryLishi(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 20,
        @Query("buytype") buytype: Int = 1,
        @Query("status") status: Int = 2,
        @Query("type") type: Int = 2,
        @Query("s_time") sTime: String? = null,
        @Query("e_time") eTime: String? = null,
    ): BaseResponse<HoldingListData>

    // ==================== Deal（普通交易） ====================

    /** 新股申购（文档 3.22）POST api/subscribe/add */
    @POST("api/subscribe/add")
    suspend fun subscribeIpo(@Body request: SubscribeIpoRequest): BaseResponse<Any>

    /** 新股申购认缴（文档 3.27）POST api/subscribe/renjiao_act */
    @POST("api/subscribe/renjiao_act")
    suspend fun renjiaoIpo(@Body request: RenjiaoRequest): BaseResponse<Any>

    /** 股票买入（文档 3.23）POST api/deal/addStrategy */
    @POST("api/deal/addStrategy")
    suspend fun addStrategy(@Body request: AddStrategyRequest): BaseResponse<Any>

    /** 根据股票代码获取持仓列表（卖出用，含T+N校验）文档 3.32 */
    @GET("api/deal/mrSellLst")
    suspend fun getMrSellList(@Query("keyword") keyword: String): BaseResponse<List<MrSellItem>>

    /** 股票卖出（H5 当前实现）POST api/deal/sell */
    @POST("api/deal/sell")
    suspend fun sell(@Body request: SellRequest): BaseResponse<Any>

    /** 股票卖出（兼容部分后端）POST api/deal/sellStock */
    @POST("api/deal/sellStock")
    suspend fun sellStockLegacy(@Body request: SellStockRequest): BaseResponse<Any>

    /** 股票买入撤单（文档 3.26）GET api/deal/cheAll */
    @GET("api/deal/cheAll")
    suspend fun cancelOrder(@Query("id") id: Int): BaseResponse<Any>

    /** 委托订单列表（文档 3.29）GET api/deal/getNowWarehouse_weituo，status=2 */
    @GET("api/deal/getNowWarehouse_weituo")
    suspend fun getEntrustList(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 10,
        @Query("buytype") buytype: String = "1,7",
        @Query("status") status: String = "2",
    ): BaseResponse<HoldingListData>

    /** 普通交易持仓列表（文档 3.30）GET api/deal/getNowWarehouse，buytype=1 status=1 */
    @GET("api/deal/getNowWarehouse")
    suspend fun getDealHoldingList(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 10,
        @Query("buytype") buytype: String = "1",
        @Query("status") status: String = "1",
    ): BaseResponse<HoldingListData>

    // ==================== Contract ====================

    @GET("api/stock/contracts")
    suspend fun getContractList(): BaseResponse<List<ContractItem>>

    @GET("api/stock/one")
    suspend fun getContractTemplateOne(): BaseResponse<ContractTemplateOneData>

    @GET("api/stock/two")
    suspend fun getContractTemplateTwo(): BaseResponse<ContractTemplateTwoData>

    @GET("api/user/contractDetail")
    suspend fun getContractDetail(@Query("id") id: Int): BaseResponse<ContractDetailData>

    @POST("api/stock/createContract")
    suspend fun createContract(@Body request: CreateContractRequest): BaseResponse<CreateContractData>

    @POST("api/user/dosignContract")
    suspend fun signContract(@Body request: SignContractRequest): BaseResponse<Any>

    // ==================== 行情 ====================

    /** 指数行情（文档 3.8）GET api/Indexnew/sandahangqing_new */
    @GET("api/Indexnew/sandahangqing_new")
    suspend fun getIndexMarket(): BaseResponse<IndexMarketData>

    /** 沪深A股列表（文档 3.15）GET api/Indexnew/getShenhuDetail */
    @GET("api/Indexnew/getShenhuDetail")
    suspend fun getShenhuList(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 50,
    ): BaseResponse<StockListWrapData>

    /** 创业板列表（文档 3.16）GET api/Indexnew/getCyDetail */
    @GET("api/Indexnew/getCyDetail")
    suspend fun getCyList(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 50,
    ): BaseResponse<StockListWrapData>

    /** 北证列表（文档 3.17）GET api/Indexnew/getBjDetail */
    @GET("api/Indexnew/getBjDetail")
    suspend fun getBjList(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 50,
    ): BaseResponse<StockListWrapData>

    /** 科创板列表（文档 3.18）GET api/Indexnew/getKcDetail */
    @GET("api/Indexnew/getKcDetail")
    suspend fun getKcList(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 50,
    ): BaseResponse<StockListWrapData>

    /** 新股可申购列表（文档 3.9）GET api/subscribe/lst */
    @GET("api/subscribe/lst")
    suspend fun getIpoList(
        @Query("page") page: Int = 1,
        @Query("type") type: Int = 0,
    ): BaseResponse<IPOListData>

    /** 股票搜索 GET api/user/searchstrategy，key 关键词 */
    @GET("api/user/searchstrategy")
    suspend fun searchStockByKey(
        @Query("key") keyword: String,
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 20,
    ): BaseResponse<StockSearchApiData>

    // ==================== 自选 ====================

    /** 股票是否已自选（文档 3.19）GET api/Indexnew/getHqinfo_1?q=allcode */
    @GET("api/Indexnew/getHqinfo_1")
    suspend fun getHqInfo(@Query("q") allcode: String): BaseResponse<HqInfoData>

    /** 自选列表（文档 3.14）GET api/elect/getZixuanNew */
    @GET("api/elect/getZixuanNew")
    suspend fun getZixuanNew(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 50,
    ): BaseResponse<StockListWrapData>

    /** 添加自选（文档 3.20）POST api/ask/addzx */
    @POST("api/ask/addzx")
    suspend fun addFavorite(@Body request: FavoriteRequest): BaseResponse<Any>

    /** 取消自选（文档 3.21）POST api/ask/delzx */
    @POST("api/ask/delzx")
    suspend fun removeFavorite(@Body request: FavoriteRequest): BaseResponse<Any>
}
