# 股票系统 API 接口文档

---

## 参数说明

### 响应 body

| 字段 | 类型 | 注释 |
|------|------|------|
| code | int | 1成功 0失败 401登录失效 |
| msg | string | 提示信息 |

---

## 一、基础接口

### 1.1 前端基础信息 和 合同模板2

- **请求URL：** `/api/stock/two`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767519384",
  "data": {
    "info": {
      "Bottom": "所有信息请如实填写",
      "Content": "<HTML合同内容>",
      "JiaName": "华泰证券股份有限公司",
      "JiaSign": "/upload/file/xrbnMl74aoy-mFHulkTWf.png",
      "Pic": "/upload/file/JC7LMJJdnzlHlB1lPAoiT.png",
      "SubTitle": "商业核心信息保密协议书",
      "Time": "2024-10-21",
      "Title": "华泰证券股份有限公司",
      "applogo": "/upload/file/FyWR5mijeSj-iP6ZcvRat.png",
      "logo": "/upload/file/5RhKgqzf2zWgNHdjEQFjg.png",
      "name": "华泰证券"
    }
  }
}
```

---

### 1.2 配置参数

- **请求URL：** `/api/stock/getconfig`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767583575",
  "data": {
    "ali_bucket": "snake-stk-test5",
    "bindkanums": "5",              // 最大绑定卡个数
    "dz_syname": "大宗交易",         // 大宗交易首页显示文字
    "dz_syshow": "1",               // 大宗交易首页显示
    "is_auth_or": "1",              // 实名通过隐藏信息
    "is_rz": 1,                     // 是否实名认证
    "is_rzconfig": "1",             // 是否需要实名认证 0关闭1显示
    "is_weituo": "0",               // 开启委托 0关闭 1开启
    "is_xgsg": "1",                 // 新股申购是否显示 0关闭1显示
    "is_xgsg_name": "新股申购",      // 新股申购名字
    "is_xxps": "1",                 // 线下配售是否显示 0关闭1显示
    "is_xxps_name": "线下配售",      // 线下配售名字
    "isauth_rz": "1",               // 认证是否上传身份证 1开启0关闭
    "kf_url": "www.kfab2c.com",     // 客服地址
    "kqssss": 0,                    // 开启输入申购数 1开 0关
    "mai_fee": "0.0001",            // 普通交易买入手续费
    "maic_fee": "0.0001",           // 统一卖出手续费
    "min_tx_money": "100",          // 最低提现
    "yh_fee": "0.0003"              // 统一印花税
  }
}
```

---

### 1.3 上传配置

- **请求URL：** `/api/user/getAlicloudSTS`
- **请求方式：** POST

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767597095",
  "data": {
    "AccessKeyId": "STS.NXmJhjsWdXksqzGJYoM1phPrP",
    "AccessKeySecret": "BYdVakt4fDDrWrW5LbMu3K3X1DGXBtrqngMGXJk5L15y",
    "Expiration": "2026-01-05T08:11:35Z",
    "RegionId": "",
    "SecurityToken": "<token>",
    "bucket": "",
    "endpoint": "https://snake-stk-test5.baihemeiye.top",
    "upload_type": "0"              // 上传类型 0阿里云 1本地上传
  }
}
```

---

### 1.4 本地上传

- **请求URL：** `/api/upload/file`
- **请求方式：** POST

**参数：**

```json
{
  "file": ""  // 文件
}
```

**返回示例：**

```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "path": "/upload/file/43c185f6-a33f-45f4-ac6e-8586815b123c.png"  // 以接口地址拼接就可以访问
  }
}
```

---

### 1.5 合同模板1

- **请求URL：** `/api/stock/one`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| page_size | 否 | string | 每页条数 |
| keyword | 否 | string | 搜索 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767600038",
  "data": {
    "info": {
      "Content": "<HTML合同内容>",
      "JiaAddress": "江苏省南京市江东中路228号",
      "JiaAddtime": "2024-10-21",
      "JiaName": "华泰证券股份有限公司",
      "JiaSign": "/upload/file/_tx-8heyhn9CUO_HTvZqV.png",
      "Pic": "/upload/file/qpj-WAw1c9FTU_5FSVeqN.png",
      "SubTitle": "证券投资顾问咨询服务协议",
      "Title": "华泰证券股份有限公司",
      "logo": "/upload/file/s0kI7SNJQaBweA6SuT86y.png"
    }
  }
}
```

---

## 二、用户

### 2.1 登录

- **请求URL：** `api/user/login`
- **请求方式：** POST

**参数：**

```json
{
  "account": "13800138008",   // 手机号
  "password": "112233"        // 密码
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "登陆成功",
  "time": "1766632019",
  "data": {
    "userinfo": {
      "avatar": "/upload/file/U0c_r0AdQtD-4aRV0HHy_.png",   // 头像
      "createtime": 1765419716,      // 创建时间
      "expires_in": 2592000,         // 有效期秒数
      "expiretime": 1769224019,      // 有效期时间戳
      "id": 1,                       // 用户id
      "mobile": "13800138008",       // 手机号
      "nickname": "138****8008",     // 昵称
      "token": "9b7c3eae-cfd2-4f57-8b9c-d0c116654438",  // 登录token
      "user_id": 1,                  // 用户id
      "username": "13800138008"      // 用户名
    }
  }
}
```

---

### 2.2 注册

- **请求URL：** `/api/user/register`
- **请求方式：** POST

**参数：**

```json
{
  "mobile": "13911112222",           // 手机号
  "password": "123456",              // 登录密码
  "payment_code": "123456",         // 支付密码
  "institution_number": "112233"    // 机构码
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "注册成功",
  "time": "1767582008",
  "data": {
    "userinfo": {
      "avatar": "/upload/file/U0c_r0AdQtD-4aRV0HHy_.png",
      "createtime": 1767582007,
      "expires_in": 2592000,
      "expiretime": 1770174008,
      "id": 6,
      "mobile": "13911112222",
      "nickname": "139****2222",
      "token": "fa4f0ff2-adb0-4fc4-9207-9c650ac13476",
      "user_id": 6,
      "username": "13911112222"
    }
  }
}
```

---

### 2.3 个人信息

- **请求URL：** `/api/stock/info`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767584121",
  "data": {
    "list": {
      "avatar": "/upload/file/U0c_r0AdQtD-4aRV0HHy_.png",  // 头像
      "balance": 982216.53,           // 余额
      "createtime": 1765419716,       // 注册时间
      "freeze_money": "",             // 冻结资产
      "freeze_profit": 0,             // 收益冻结T+1
      "id": 1,                        // 用户id
      "isContract": "1",              // 是否展示合同 1:展示 0:隐藏
      "isEditBuy": "1",               // 买入价格是否可编辑 1:可以 0:不可以
      "is_auth": 1,                   // 是否实名认证 0未实名 1已实名
      "is_authentication": "1",       // 实名认证状态
      "is_card": 0,                   // 是否绑卡
      "is_cash": 1,                   // 可否提现
      "is_cc": 1,                     // 是否有持仓
      "is_dz": 1,                     // 大宗 0关闭 1打开
      "is_ps": 1,                     // 配售 0关闭 1打开
      "is_recharge": 1,               // 是否开启充值
      "is_rz": 1,                     // 是否实名认证 0未实名 1已实名
      "is_sg": 1,                     // 申购 0关闭 1打开
      "jingzhijiaoyi": "0",           // 是否禁止交易
      "loginip": "127.0.0.1",         // 登录ip
      "logintime": 1767582380,        // 登录时间
      "mobile": "13800138008",        // 手机号
      "money": 982216.53,             // 余额
      "nickname": "测试",              // 昵称
      "status": "normal",             // 状态 normal正常 其他禁用
      "xx_num": 0                     // 未读消息数
    }
  }
}
```

---

### 2.4 合同创建

- **请求URL：** `/api/stock/createContract`
- **请求方式：** POST

**参数：**

```json
{
  "type": 1,          // 合同类型 列表返回
  "address": "111"    // 地址
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767591034",
  "data": {
    "contract_id": "3",   // 合同id
    "id": "3"
  }
}
```

---

### 2.5 合同签约

- **请求URL：** `/api/user/dosignContract`
- **请求方式：** POST

**参数：**

```json
{
  "id": "10",                                              // 合同id
  "img": "/image/uxdViHt8wSnvFiiZZ9sIPASV98uZKyKG.png"    // 签约图片
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "签署成功",
  "time": "1767591461",
  "data": null
}
```

---

### 2.6 资产（个人中心）

- **请求URL：** `/api/user/getUserPrice_all`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767592287",
  "data": {
    "list": {
      "balance": 982216.53,                // 余额
      "city_value": 64888,                 // 市值
      "fdyk": 29226,                       // 浮动盈亏
      "freeze_profit": 0,                  // t+1冻结金额
      "property_money_total": 1047104.53,  // 总资产
      "totalyk": 3332,                     // 累计盈亏
      "xingu_total": 0                     // 新股申购
    }
  }
}
```

---

### 2.7 资产（交易）

- **请求URL：** `/api/user/getUserPrice_all1`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767592290",
  "data": {
    "list": {
      "balance": 982216.53,                // 余额
      "city_value": 62672,                 // 市值
      "fdyk": 28020,                       // 浮动盈亏
      "freeze_profit": 0,                  // t+1冻结金额
      "property_money_total": 1044888.53,  // 总资产
      "totalyk": 0,                        // 累计盈亏
      "weituozj": 0                        // 委托占用
    }
  }
}
```

---

### 2.8 实名认证详情

- **请求URL：** `/api/user/authenticationDetail`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 0,
  "msg": "success",
  "time": "1767597744",
  "data": {
    "detail": {
      "auth_contact": "<HTML描述文字>",
      "backcardimage": "/upload/file/xxx.png",       // 身份证背面
      "frontcardimage": "/upload/file/xxx.png",      // 身份证正面
      "id": 2,
      "id_card": "420521198402154410",               // 身份证号
      "is_audit": "1",    // 实名状态 0=待审 1=审核通过 2=驳回 3=审核中
      "name": "测试",     // 实名姓名
      "reject": "",       // 拒绝原因
      "user_id": 1
    }
  }
}
```

---

### 2.9 提交实名认证

- **请求URL：** `/api/user/authentication`
- **请求方式：** POST

**参数：**

```json
{
  "name": "111",        // 姓名
  "id_card": "111",     // 身份证号
  "f": "/xxxx",         // 正面照片
  "b": "/bbb"           // 背面照片
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 2.10 银行卡列表

- **请求URL：** `/api/user/accountLst`
- **请求方式：** POST

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767598647",
  "data": {
    "bindkanums": "5",
    "list": {
      "current_page": 10,
      "data": [
        {
          "id": 1,
          "user_id": 1,
          "name": "测试",                // 姓名
          "account": "6217111122223333", // 卡号
          "deposit_bank": "测试银行",     // 银行名称
          "khzhihang": "测试分行",        // 支行名称
          "createtime": 1765720368
        }
      ],
      "last_page": 1,
      "per_page": 1,
      "total": 1
    }
  }
}
```

---

### 2.11 绑定银行卡

- **请求URL：** `/api/user/bindaccount`
- **请求方式：** POST

**参数：**

```json
{
  "name": "测试",              // 姓名
  "khzhihang": "农业",         // 支行名称
  "deposit_bank": "农业银行",  // 银行名称
  "account": "6211222233334444",  // 卡号
  "id": 16                    // 有id就是编辑 没有就是新增
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 2.12 银证转入 和 银证记录

- **请求URL：** `/api/user/capitalLog`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| type | 否 | string | 0转入 1转出 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767598934",
  "data": {
    "bank_list": [
      {
        "id": 117,
        "bankinfo": "paysanguo",
        "tdname": "银证转入",         // 通道名称
        "yzmima": "",                // 银证密码
        "minlow": 100,               // 最小金额
        "maxhigh": 1111,             // 最大金额
        "url_type": 1                // 支付方式 1嵌入 2外部浏览器
      }
    ],
    "kq_cancle": "0",               // 开启客户主动取消提现 1:打开 0:关闭
    "list": [
      {
        "biz": "人民币",              // 币种
        "createtime": 1766469373,
        "id": 5,
        "is_pay": "0",               // 是否成功
        "is_pay_name": "银证转出中",
        "money": 333,                // 金额
        "pay_type_name": "银证转出",  // 描述文字
        "reject": "",                // 拒绝原因
        "txtcolor": "blue"           // 文字颜色
      }
    ],
    "userInfo": {
      "balance": 982216.53,          // 用户余额
      "freeze_profit": 0             // 用户t+1资金
    },
    "yhxy": "<HTML银证转入描述文字>"
  }
}
```

---

### 2.13 验证支付密码

- **请求URL：** `/api/user/checkOldpay`
- **请求方式：** POST

**参数：**

```json
{
  "paypass": "111111"   // 支付密码
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 2.14 修改支付密码

- **请求URL：** `/api/user/editPass`
- **请求方式：** POST

**参数：**

```json
{
  "password": "111111"   // 新的支付密码
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 2.15 合同列表

- **请求URL：** `/api/stock/contracts`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767599650",
  "data": [
    {
      "id": 1,
      "link": "",
      "name": "证券投资顾问咨询服务协议",   // 名称
      "status": 1,                        // 是否签署 1否 2是
      "type": 1
    },
    {
      "id": 0,
      "link": "",
      "name": "商业核心信息保密协议书",
      "status": 0,
      "type": 2
    }
  ]
}
```

---

### 2.16 发起提现

- **请求URL：** `/api/user/sendCode`
- **请求方式：** GET

**参数：**

```json
{
  "account_id": "1",       // 银行卡
  "money": 10,             // 金额
  "pass": "112222"         // 支付密码
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 2.17 合同详情

- **请求URL：** `/api/user/contractDetail?id=8`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| id | 否 | string | 合同id |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767599789",
  "data": {
    "info": {
      "address": "包i宝宝",                      // 地址
      "createtime": 1765721116,                  // 创建时间
      "currenttime": 1767599788,                 // 当前时间
      "id": 1,
      "idnumber": "420521198402154410",          // 身份证号
      "name": "测试",                             // 姓名
      "signDate": "2025年12月14日",               // 签约时间
      "signimage": "/upload/file/xxx.png",       // 签约图片
      "signtime": 1765721312,                    // 签约时间
      "tgdata": "2",         // 是否签名 1=否 2=是
      "typedata": "1",       // 合同模版 1=模版一 2=模版二
      "user_id": 1
    }
  }
}
```

---

### 2.18 发起充值

- **请求URL：** `/api/user/recharge`
- **请求方式：** POST

**参数：**

```json
{
  "money": "123",        // 金额
  "sysbankid": 109       // 通道id
}
```

**返回示例（成功）：**

```json
{
  "retCode": 0,
  "retMsg": "success",
  "payJumpUrl": "http://www.baidu.com"
}
```

**返回示例（失败）：**

```json
{
  "retCode": 1,
  "retMsg": "失败提示"
}
```

---

### 2.19 银证转入配置

- **请求URL：** `/api/index/getchargeconfignew`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767669874",
  "data": {
    "charge_low": "100",                       // 最低充值金额
    "contentmsg_gb": "<HTML转入描述>",
    "is_sm": 1,                                // 是否有开启的通道
    "min_tx_money": "100",                     // 最低提现金额
    "sysbank_list": [
      {
        "id": 117,
        "bankinfo": "paysanguo",
        "tdname": "银证转入",                    // 通道名称
        "yzmima": "",                           // 银证密码
        "minlow": 100,                          // 最小充值
        "maxhigh": 1111,                        // 最大充值
        "url_type": 1                           // 类型 1嵌入 2外部浏览器
      }
    ]
  }
}
```

---

### 2.20 支付通道详情

- **请求URL：** `/api/index/getyhkconfignew?bankid=117`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| bankid | 否 | string | 通道id |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767670124",
  "data": {
    "charge_low": "100",              // 最小充值金额
    "list": [
      {
        "id": 117,
        "bankinfo": "paysanguo",
        "tdname": "银证转入",          // 通道名称
        "yzmima": "",                 // 银证密码
        "minlow": 100,                // 最小充值
        "maxhigh": 1111,              // 最大充值
        "url_type": 1                 // 类型 1嵌入 2外部浏览器
      }
    ],
    "tips": "<p><br></p>"
  }
}
```

---

## 三、首页 & 行情

### 3.1 新闻列表

- **请求URL：** `/api/Indexnew/getGuoneinews`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 是 | string | 页码 |
| size | 是 | string | 每页条数 |
| type | 是 | string | 类型 1国内经济 2国际经济 3证券要闻 4公司咨询 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767582389",
  "data": {
    "list": [
      {
        "news_time": "2026-01-05 10:55:38",          // 新闻时间
        "news_image": "",                             // 新闻图片(mode为4时有值)
        "news_id": "202601053608561157",              // 新闻id
        "news_title": "广州南沙新年第一会：释放重要发展信号",  // 新闻标题
        "news_content": "<HTML新闻内容>",              // 新闻内容
        "news_abstract": "新闻简述...",                // 新闻简述
        "id": 378865,
        "type": 1,
        "mode": 6,
        "news_time_text": "2026-01-05 10:55:38"      // 新闻时间
      }
    ],
    "page": 1
  }
}
```

---

### 3.2 新闻详情

- **请求URL：** `/api/Indexnew/getNewsssDetail?news_id=202601043607930455`
- **请求方式：** GET

**参数：**

```json
{
  "news_id": "202601043607930455"   // 新闻id
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767582749",
  "data": {
    "news_time": "2026-01-04 17:46:29",           // 新闻时间
    "news_image": "",                              // mode为4时有值
    "news_id": "202601043607930455",               // 新闻id
    "news_title": "机构论后市丨春季行情可能缓步启动", // 新闻标题
    "news_content": "<HTML新闻内容>",               // 新闻内容
    "news_abstract": "新闻简述...",                 // 新闻简述
    "id": 377339,
    "type": 3,
    "mode": 6
  }
}
```

---

### 3.3 轮播图

- **请求URL：** `/api/index/banner`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767583184",
  "data": {
    "list": [
      {
        "id": 71,
        "title": "",
        "image": "/upload/file/2i588YA5pST3-6-xQ2CB5.jpg",  // 图片
        "link": "",                                           // 跳转地址
        "createtime": 1765097177
      }
    ]
  }
}
```

---

### 3.4 消息列表

- **请求URL：** `/api/news/index`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 是 | string | 页码 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767583298",
  "data": {
    "list": {
      "current_page": 1,
      "data": [
        {
          "createtime": "2025-12-24",    // 消息发送时间
          "id": 1,
          "is_read": "0",               // 是否已读
          "title": "欢迎使用"            // 标题
        }
      ],
      "last_page": 1,
      "per_page": 50,
      "total": 1
    }
  }
}
```

---

### 3.5 消息详情

- **请求URL：** `/api/news/detail?id=1`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| id | 是 | int | 消息id |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767583468",
  "data": {
    "detail": "<HTML消息内容>"   // 消息内容
  }
}
```

---

### 3.6 股票开启状态

- **请求URL：** `/api/Indexnew/sgandps`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767584544",
  "data": {
    "is_dzjy": "1",              // 大宗交易首页显示
    "is_xgsg": "1",              // 新股申购是否显示
    "is_xxps": "1",              // 线下配售是否展示
    "list_dzjy": [],             // 大宗交易列表
    "list_dzjy_count": 0,        // 大宗交易数量
    "list_ps": [],               // 配售股票列表
    "list_ps_count": 0,          // 配售股票数量
    "list_sg": [],               // 申购股票列表
    "list_sg_count": 0,          // 申购数量
    "name_dzjy": "大宗交易",      // 大宗交易名称
    "name_xgsg": "新股申购",      // 新股申购名称
    "name_xxps": "线下配售"       // 线下配售名称
  }
}
```

---

### 3.7 新股申购已中签未认缴数据

- **请求URL：** `/api/stock/ballot`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767591712",
  "data": {
    "count": 1,
    "info": [
      {
        "id": 1,
        "code": "920121",           // 股票code
        "name": "江天科技",          // 股票名称
        "sg_fx_price": 21.21,       // 申购价
        "status": "1",              // 状态 0=申购中 1=中签 2=未中签 3=弃购
        "zq_num": 1000,             // 中签数(股)
        "zq_nums": 10,              // 中签数量(手)
        "renjiao": "0",             // 是否认缴
        "is_cc": "1",               // 是否转入持仓 0:未转入 1:已转入 2:弃
        "zq_money": 21210           // 中签后价格
      }
    ],
    "is_rj": 1
  }
}
```

---

### 3.8 指数行情

- **请求URL：** `/api/Indexnew/sandahangqing_new`
- **请求方式：** GET

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767591996",
  "data": {
    "list": [
      {
        "title": "上证指数",            // 指数名称
        "code": "000001",              // 指数代码
        "allcode": "sh000001",         // 指数完整代码
        "allcodes_arr": [
          "1",            // 市场标识 1=上海 51=深圳
          "上证指数",       // 名称
          "000001",        // 代码
          "4012.37",       // 最新价/最新点位
          "43.53",         // 涨跌额
          "1.10",          // 涨跌幅(%)
          "461177020",     // 成交量(手)
          "83711736",      // 成交额(万)
          "",              // 预留字段
          "655029.38",     // 总市值
          "ZS"             // 类型 ZS=指数
        ]
      }
    ]
  }
}
```

> 返回的指数包括：上证指数、上证380、上证180、上证50、沪深300、深证成指、中小100、创业板指

---

### 3.9 新股可申购列表

- **请求URL：** `/api/subscribe/lst?page=1&type=0`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 是 | string | 页码 |
| type | 是 | string | 0已开启新股申购 1已到申购时间但是未上市 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767592938",
  "data": {
    "list": [
      {
        "flag": 1,
        "sub_info": [
          {
            "id": 999,
            "code": "920086",              // 股票code
            "name": "科马材料",             // 股票名称
            "sgcode": "920086",            // 申购code
            "fx_num": "20920000",          // 发行数量
            "wsfx_num": "18828000",        // 网上发行
            "sg_limit": "99999999",        // 申购上限
            "fx_price": "11.66",           // 发行价格
            "fx_rate": "14.2",             // 发行市盈率
            "sg_date": "2026-01-06",       // 申购日期
            "zq_rate": "0",                // 中签率(%)
            "ss_date": "0000-00-00",       // 上市日期
            "sgswitch": 1,                 // 申购开关 0关闭 1开启
            "xxswitch": 1,                 // 线下配售 0关闭 1开启
            "content": "",                 // 申购秘钥
            "sg_type": "4",                // 1沪 2深 3创 5科 4京
            "industry": ""                 // 所属行业
          }
        ]
      }
    ],
    "maxxg": 0
  }
}
```

---

### 3.10 已申购新股列表

- **请求URL：** `/api/subscribe/getsgnewgu0`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |
| status | 否 | string | 申购状态 0=申购中 1=中签 2=未中签 3=弃购 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767593388",
  "data": {
    "dxlog_list": [
      {
        "id": 1,
        "code": "920121",
        "name": "江天科技",
        "sg_fx_price": 21.21,           // 申购价
        "status": "1",                  // 状态 0=申购中 1=中签 2=未中签 3=弃购
        "zq_num": 1000,                 // 数量
        "zq_nums": 10,                  // 手数
        "renjiao": "1",                 // 是否认缴
        "is_cc": "1",                   // 是否转持仓
        "zq_money": 21210,              // 中签价格
        "codejson": {                   // 标题样式
          "color": "#ff6219",
          "size": 28,
          "text": "江天科技"
        },
        "tag": {                        // tag样式
          "color": "#ff6219",
          "size": 28,
          "text": "中签10(股)(已认缴)"
        },
        "status_txt": "中签10(股)(已认缴)",
        "sg_ss_date": "2025-12-25",     // 上市时间
        "sg_ss_tag": 1,                 // 是否有上市时间
        "createtime_txt": "2025-12-16"
      }
    ],
    "kq_zdrj": "1"
  }
}
```

---

### 3.11 新股详情

- **请求URL：** `/api/subscribe/lstDetail`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| id | 是 | string | 新股id |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767593646",
  "data": {
    "info": {
      "id": 970,
      "code": "603092",              // 股票代码
      "name": "德力佳",              // 股票名称
      "sgcode": "732092",           // 申购代码
      "fx_num": "40000100",         // 发行数量
      "wsfx_num": "9600000",        // 网上发行
      "sg_limit": "99999999",       // 申购上限
      "fx_price": "46.68",          // 发行价
      "fx_rate": "34.98",           // 发行市盈率
      "sg_date": "2025-10-28",      // 申购日期
      "zq_rate": "0.0260244",       // 中签率(%)
      "ss_date": "2025-11-07",      // 上市日期
      "content": "",                // 申购秘钥
      "sg_type": "1",               // 1沪 2深 3创 5科 4京
      "sg_type_text": "沪市",
      "industry": ""                // 所属行业
    },
    "kqssss": 0,
    "maxxg": 0,
    "psmax": "10000000"             // 配售最大手数
  }
}
```

---

### 3.12 线下配售可申购列表

- **请求URL：** `/api/subscribe/xxlst?page=1&type=0`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 是 | string | 页码 |
| type | 是 | string | 0已开启线下配售 1已到申购时间但是未上市 |

**返回示例：**

> 返回格式与「新股可申购列表」一致

---

### 3.13 大宗可申购列表

- **请求URL：** `/api/dzjy/lst`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767594929",
  "data": {
    "balance": 982216.53,             // 余额
    "list": [
      {
        "id": 6452,
        "title": "健信超导",           // 股票名称
        "code": "688805",             // 股票code
        "allcode": "sh688805",        // 股票完整code
        "cai_buy": "18.58",           // 增发价格
        "status": "0",                // 0开启 1关闭
        "type": 5,                    // 1:沪 2:深 3:创业 4:北交 5:科创 6:基金
        "is_dz": 1,                   // 开启大宗交易 0关闭 1开启
        "is_zfa": 0,                  // 开启增发交易 0关闭 1开启
        "pingday": 1,                 // 增发平仓天数
        "zfanum": 9900,               // 增发数量万起
        "zfrate": 0,                  // 增发比例(%)
        "totalbuy": 100,              // 已增发数量
        "cai_price": "43.73",         // 当前价格
        "max_num": 529,               // 最大可购买
        "p": 1,                       // 已增发百分比
        "rate": 57.51                 // 价格比例(%)
      }
    ]
  }
}
```

---

### 3.14 自选列表

- **请求URL：** `/api/elect/getZixuanNew`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767596130",
  "data": {
    "list": [
      {
        "buy": "61852558",             // 成交量
        "changepercent": "20.01",      // 今开
        "code": "688108",              // 股票代码
        "name": "赛诺医疗",            // 股票名称
        "open": "96.07",               // 买一价
        "pricechange": "3.85",         // 昨收
        "sell": "137007",              // 外盘
        "settlement": "",              // 内盘
        "symbol": "sh688108",          // 股票完整代码
        "trade": "23.09"               // 当前价
      }
    ]
  }
}
```

---

### 3.15 沪深列表

- **请求URL：** `/api/Indexnew/getShenhuDetail`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |

**返回示例：**

> 返回格式与「自选列表」一致

---

### 3.16 创业列表

- **请求URL：** `/api/Indexnew/getCyDetail`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |

**返回示例：**

> 返回格式与「自选列表」一致

---

### 3.17 北证列表

- **请求URL：** `/api/Indexnew/getBjDetail`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |

**返回示例：**

> 返回格式与「自选列表」一致

---

### 3.18 科创列表

- **请求URL：** `/api/Indexnew/getKcDetail`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |

**返回示例：**

> 返回格式与「自选列表」一致

---

### 3.19 股票是否已自选

- **请求URL：** `/api/Indexnew/getHqinfo_1?q=bj920726`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| q | 否 | string | 完整代码 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767596930",
  "data": {
    "is_zq": 1,       // 是否实名 0未实名 1已实名
    "is_zx": 0        // 是否加入自选
  }
}
```

---

### 3.20 添加自选

- **请求URL：** `/api/ask/addzx`
- **请求方式：** POST

**参数：**

```json
{
  "allcode": "sz300102",    // 完整code
  "code": "300102"          // code
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 3.21 取消自选

- **请求URL：** `/api/ask/delzx`
- **请求方式：** POST

**参数：**

```json
{
  "allcode": "sz300102",    // 完整code
  "code": "300102"          // code
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 3.22 新股申购

- **请求URL：** `/api/subscribe/add`
- **请求方式：** POST

**参数：**

```json
{
  "code": "301667"    // 新股code
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 3.23 股票买入

- **请求URL：** `/api/deal/addStrategy`
- **请求方式：** POST

**参数：**

```json
{
  "allcode": "sz300204",    // 买入股票的完整代码
  "buyprice": 30.3,         // 买入价格
  "canBuy": 1               // 买入手数
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 3.24 大宗交易买入

- **请求URL：** `/api/dzjy/addStrategy_zfa`
- **请求方式：** POST

**参数：**

```json
{
  "allcode": "sh111111",    // 股票完整代码
  "canBuy": 1,              // 买入手数
  "miyao": "111"            // 秘钥
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 3.25 线下配售买入

- **请求URL：** `/api/subscribe/xxadd`
- **请求方式：** POST

**参数：**

```json
{
  "code": "920005",       // 股票code
  "sg_nums": 6,           // 买入手数
  "miyao": ""              // 秘钥
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 3.26 股票买入撤单

- **请求URL：** `/api/deal/cheAll`
- **请求方式：** GET

**参数：**

```json
{
  "id": 2    // 委托id
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 3.27 新股申购认缴

- **请求URL：** `/api/subscribe/renjiao_act`
- **请求方式：** POST

**参数：**

```json
{
  "id": 1    // 新股申购id
}
```

**返回示例：**

```json
{
  "code": 1,
  "msg": "success"
}
```

---

### 3.28 股票搜索

- **请求URL：** `/api/user/searchstrategy`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |
| key | 否 | string | 搜索关键字 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767608396",
  "data": {
    "list": [
      {
        "allcode": "sz301122",        // 股票完整代码
        "code": "301122",             // 股票代码
        "latter": "CNGF",             // 简称
        "name": "采纳股份",
        "title": "采纳股份",           // 股票名称
        "type": 3                     // 1:沪 2:深 3:创业 4:北交 5:科创 6:基金
      }
    ]
  }
}
```

---

### 3.29 委托订单列表

- **请求URL：** `/api/deal/getNowWarehouse_weituo?buytype=1,7&page=1&size=10&status=2`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |
| buytype | 否 | string | 交易类型 1普通 7增发(大宗)，一般传递1,7表示两种类型都拉取 |
| status | 否 | string | 固定为2 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767677435",
  "data": {
    "list": [
      {
        "allcode": "bj920121",
        "buyprice": 21.21,                  // 下单价格
        "buytype": "1",                     // 交易类型 1普通 7增发(大宗)
        "canBuy": "10",                     // 下单手数
        "citycc": 45200,                    // 市值
        "cjlx": "挂单",                     // 状态描述
        "code": "920121",                   // 股票代码
        "createtime_name": "2025-12-18 09:20:00",  // 下单时间
        "creditMoney": 21210,
        "number": "1000",                   // 下单股数
        "profitLose": 23990,                // 盈亏
        "profitLose_rate": "113.11%",       // 盈亏比例
        "status": 2,    // 状态 1当前持仓 2当前委托 3历史交易 4已撤单
        "title": "江天科技",                 // 股票名称
        "type": 4       // 类型 1:沪 2:深 3:创业 4:北交 5:科创 6:基金
      }
    ]
  }
}
```

---

### 3.30 普通交易持仓列表

- **请求URL：** `/api/deal/getNowWarehouse?buytype=1&page=1&size=10&status=1`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |
| buytype | 否 | string | 固定为1 |
| status | 否 | string | 固定为1 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767678718",
  "data": {
    "list": [
      {
        "allMoney": "0.23",                    // 手续费
        "allcode": "sh688108",
        "buyprice": 22.59,                     // 购买价格
        "cai_buy": 22.42,                      // 当前价格
        "canBuy": "1",                         // 手数
        "citycc": 2242,                        // 市值
        "code": "688108",                      // 股票code
        "createtime_name": "2026-01-06 13:31:47",  // 买入时间
        "number": "100",                       // 股数
        "profitLose": -17,                     // 盈亏
        "profitLose_rate": "-0.75%",           // 盈亏比例
        "title": "赛诺医疗",                    // 股票标题
        "type": 5   // 类型 1:沪 2:深 3:创业 4:北交 5:科创 6:基金
      }
    ],
    "position_money": 3591,                    // 持仓盈亏
    "total_city_value": 19292                  // 总市值
  }
}
```

---

### 3.31 普通交易历史持仓

- **请求URL：** `/api/deal/getNowWarehouse_lishi?buytype=1&e_time=2026-12-06&page=1&s_time=2025-11-30&size=10&status=2`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |
| s_time | 否 | string | 开始时间 2025-11-30 |
| e_time | 否 | string | 结束时间 2026-12-06 |
| buytype | 否 | string | 固定为1 |
| status | 否 | string | 固定为2 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767679147",
  "data": {
    "list": [
      {
        "allMoney": "0.23",                      // 买入手续费
        "allcode": "sh688108",
        "buyprice": 22.59,                       // 买入价格
        "cai_buy": "22.4",                       // 卖出价格
        "code": "688108",                        // 股票code
        "createtime_name": "2026-01-06 13:31:47",  // 买入时间
        "money": "2259.23",                      // 本金
        "number": "100",                         // 股数
        "outtime_name": "2026-01-06 13:56:38",   // 卖出时间
        "profitLose": -19,                       // 盈亏
        "title": "赛诺医疗",                      // 股票名称
        "type": 5,   // 类型 1:沪 2:深 3:创业 4:北交 5:科创 6:基金
        "yhfee": "0.68"                          // 印花税
      }
    ]
  }
}
```

---

### 3.32 根据股票代码获取持仓列表（卖出用）

- **请求URL：** `/api/deal/mrSellLst?keyword=300516`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| keyword | 否 | string | 股票代码 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767679837",
  "data": [
    {
      "id": 1,
      "code": "300516",                  // 股票code
      "allcode": "sz300516",
      "title": "久之洋",                 // 股票名称
      "canBuy": "2",                     // 手数
      "buyprice": "67.21",               // 买入价
      "number": "200",                   // 股票数量
      "type": 3
    }
  ]
}
```

---

### 3.33 大宗交易持仓列表

- **请求URL：** `/api/dzjy/getNowWarehouse?buytype=7&page=1&size=10&status=1`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |
| status | 否 | string | 固定为1 |
| buytype | 否 | string | 固定为7 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767680351",
  "data": {
    "list": [
      {
        "allMoney": "0.1",                      // 手续费
        "allcode": "sh603248",
        "buyprice": 10.1,                       // 买入价格
        "cai_buy": 22.3,                        // 当前价格
        "citycc": 2230,                         // 市值
        "code": "603248",                       // 股票代码
        "createtime_name": "2025-12-26 10:47:18",  // 买入时间
        "number": "100",                        // 股票数量
        "profitLose": 1220,                     // 盈亏
        "profitLose_rate": "120.79%",           // 收益率
        "title": "锡华科技",                     // 股票名称
        "type": 1   // 1:沪 2:深 3:创业 4:北交 5:科创 6:基金
      }
    ],
    "position_money": 1220,                     // 持仓盈亏
    "total_city_value": 2230                    // 总市值
  }
}
```

---

### 3.34 大宗交易历史持仓列表

- **请求URL：** `/api/dzjy/getNowWarehouse_lishi?buytype=1&page=1&size=10&status=2`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |
| buytype | 否 | string | 固定为1 |
| status | 否 | string | 固定为2 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1767680992",
  "data": {
    "list": [
      {
        "allMoney": "0.23",                      // 买入手续费
        "allcode": "sh688108",
        "buyprice": 22.59,                       // 买入价格
        "cai_buy": "22.4",                       // 卖出价格
        "citycc": 2259,                          // 市值
        "code": "688108",                        // 股票代码
        "createtime_name": "2026-01-06 13:31:47",  // 买入时间
        "number": "100",                         // 股票数量
        "outtime_name": "2026-01-06 13:56:38",   // 卖出时间
        "profitLose": -19,                       // 盈亏
        "profitLose_rate": "-0.84%",             // 盈亏比例
        "title": "赛诺医疗",                      // 股票名称
        "type": 5,
        "yhfee": "0.68"                          // 印花税
      }
    ],
    "position_money": -19,
    "total_city_value": 2259
  }
}
```

---

### 3.35 线下配售列表

- **请求URL：** `/api/subscribe/getsgnewgu`
- **请求方式：** GET

**参数：**

| 参数名 | 必选 | 类型 | 说明 |
|--------|------|------|------|
| page | 否 | string | 页码 |
| size | 否 | string | 每页条数 |
| status | 否 | string | 状态 0申购中 1中签 2未中签 3弃购 |

**返回示例：**

```json
{
  "code": 1,
  "msg": "success",
  "time": "1769502834",
  "data": {
    "dxlog_list": [
      {
        "id": 2,
        "code": "301687",              // 股票代码
        "name": "新广益",              // 股票名称
        "sg_fx_price": 21.93,          // 发行价
        "sg_num": 5,                   // 申购手数
        "sg_nums": 500,                // 申购数量
        "status": "1",                 // 0申购中 1中签 2未中签 3弃购
        "money": "10965",              // 配售保证金
        "zq_num": 0,                   // 中签数量
        "is_cc": "0",                  // 是否转持仓
        "zq_money": 0,                 // 中签金额
        "zq_nums": 0,                  // 中签手数
        "codejson": {
          "color": "#ed3f14",
          "size": 28,
          "text": "新广益"
        },
        "tag": {
          "color": "#EC4028",
          "size": 28,
          "text": "中签0(手)"
        },
        "status_txt": "中签0(手)",      // 描述文字
        "sg_ss_date": "2025-12-31",
        "sg_ss_tag": 1,
        "createtime_txt": "2026-01-26",
        "dj_money": 0
      }
    ]
  }
}
```

---

## 接口汇总表

| 序号 | 模块 | 接口名称 | URL | 方法 |
|------|------|----------|-----|------|
| 1 | 基础接口 | 前端基础信息和合同模板2 | `/api/stock/two` | GET |
| 2 | 基础接口 | 配置参数 | `/api/stock/getconfig` | GET |
| 3 | 基础接口 | 上传配置 | `/api/user/getAlicloudSTS` | POST |
| 4 | 基础接口 | 本地上传 | `/api/upload/file` | POST |
| 5 | 基础接口 | 合同模板1 | `/api/stock/one` | GET |
| 6 | 用户 | 登录 | `api/user/login` | POST |
| 7 | 用户 | 注册 | `/api/user/register` | POST |
| 8 | 用户 | 个人信息 | `/api/stock/info` | GET |
| 9 | 用户 | 合同创建 | `/api/stock/createContract` | POST |
| 10 | 用户 | 合同签约 | `/api/user/dosignContract` | POST |
| 11 | 用户 | 资产(个人中心) | `/api/user/getUserPrice_all` | GET |
| 12 | 用户 | 资产(交易) | `/api/user/getUserPrice_all1` | GET |
| 13 | 用户 | 实名认证详情 | `/api/user/authenticationDetail` | GET |
| 14 | 用户 | 提交实名认证 | `/api/user/authentication` | POST |
| 15 | 用户 | 银行卡列表 | `/api/user/accountLst` | POST |
| 16 | 用户 | 绑定银行卡 | `/api/user/bindaccount` | POST |
| 17 | 用户 | 银证转入和银证记录 | `/api/user/capitalLog` | GET |
| 18 | 用户 | 验证支付密码 | `/api/user/checkOldpay` | POST |
| 19 | 用户 | 修改支付密码 | `/api/user/editPass` | POST |
| 20 | 用户 | 合同列表 | `/api/stock/contracts` | GET |
| 21 | 用户 | 发起提现 | `/api/user/sendCode` | GET |
| 22 | 用户 | 合同详情 | `/api/user/contractDetail` | GET |
| 23 | 用户 | 发起充值 | `/api/user/recharge` | POST |
| 24 | 用户 | 银证转入配置 | `/api/index/getchargeconfignew` | GET |
| 25 | 用户 | 支付通道详情 | `/api/index/getyhkconfignew` | GET |
| 26 | 首页&行情 | 新闻列表 | `/api/Indexnew/getGuoneinews` | GET |
| 27 | 首页&行情 | 新闻详情 | `/api/Indexnew/getNewsssDetail` | GET |
| 28 | 首页&行情 | 轮播图 | `/api/index/banner` | GET |
| 29 | 首页&行情 | 消息列表 | `/api/news/index` | GET |
| 30 | 首页&行情 | 消息详情 | `/api/news/detail` | GET |
| 31 | 首页&行情 | 股票开启状态 | `/api/Indexnew/sgandps` | GET |
| 32 | 首页&行情 | 新股申购已中签未认缴数据 | `/api/stock/ballot` | GET |
| 33 | 首页&行情 | 指数行情 | `/api/Indexnew/sandahangqing_new` | GET |
| 34 | 首页&行情 | 新股可申购列表 | `/api/subscribe/lst` | GET |
| 35 | 首页&行情 | 已申购新股列表 | `/api/subscribe/getsgnewgu0` | GET |
| 36 | 首页&行情 | 新股详情 | `/api/subscribe/lstDetail` | GET |
| 37 | 首页&行情 | 线下配售可申购列表 | `/api/subscribe/xxlst` | GET |
| 38 | 首页&行情 | 大宗可申购列表 | `/api/dzjy/lst` | GET |
| 39 | 首页&行情 | 自选列表 | `/api/elect/getZixuanNew` | GET |
| 40 | 首页&行情 | 沪深列表 | `/api/Indexnew/getShenhuDetail` | GET |
| 41 | 首页&行情 | 创业列表 | `/api/Indexnew/getCyDetail` | GET |
| 42 | 首页&行情 | 北证列表 | `/api/Indexnew/getBjDetail` | GET |
| 43 | 首页&行情 | 科创列表 | `/api/Indexnew/getKcDetail` | GET |
| 44 | 首页&行情 | 股票是否已自选 | `/api/Indexnew/getHqinfo_1` | GET |
| 45 | 首页&行情 | 添加自选 | `/api/ask/addzx` | POST |
| 46 | 首页&行情 | 取消自选 | `/api/ask/delzx` | POST |
| 47 | 首页&行情 | 新股申购 | `/api/subscribe/add` | POST |
| 48 | 首页&行情 | 股票买入 | `/api/deal/addStrategy` | POST |
| 49 | 首页&行情 | 大宗交易买入 | `/api/dzjy/addStrategy_zfa` | POST |
| 50 | 首页&行情 | 线下配售买入 | `/api/subscribe/xxadd` | POST |
| 51 | 首页&行情 | 股票买入撤单 | `/api/deal/cheAll` | GET |
| 52 | 首页&行情 | 新股申购认缴 | `/api/subscribe/renjiao_act` | POST |
| 53 | 首页&行情 | 股票搜索 | `/api/user/searchstrategy` | GET |
| 54 | 首页&行情 | 委托订单列表 | `/api/deal/getNowWarehouse_weituo` | GET |
| 55 | 首页&行情 | 普通交易持仓列表 | `/api/deal/getNowWarehouse` | GET |
| 56 | 首页&行情 | 普通交易历史持仓 | `/api/deal/getNowWarehouse_lishi` | GET |
| 57 | 首页&行情 | 根据股票代码获取持仓列表(卖出用) | `/api/deal/mrSellLst` | GET |
| 58 | 首页&行情 | 大宗交易持仓列表 | `/api/dzjy/getNowWarehouse` | GET |
| 59 | 首页&行情 | 大宗交易历史持仓列表 | `/api/dzjy/getNowWarehouse_lishi` | GET |
| 60 | 首页&行情 | 线下配售列表 | `/api/subscribe/getsgnewgu` | GET |
