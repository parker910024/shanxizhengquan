package ex.ss.lib.components.mmkv

import kotlin.properties.ReadWriteProperty
import kotlin.reflect.KClass
import kotlin.reflect.KProperty
import kotlin.reflect.cast
import kotlin.reflect.safeCast

inline fun <reified T : Any> kvDelegate(defValue: T) = MMKVDelegate(T::class, defValue)

class MMKVDelegate<T : Any>(private val clazz: KClass<T>, private val defValue: T) :
    ReadWriteProperty<IMMKVDelegate, T> {

    override fun getValue(thisRef: IMMKVDelegate, property: KProperty<*>): T {
        val kv = thisRef.mmkv()
        val key = property.name
        val value = when (clazz) {
            Boolean::class -> {
                kv.decodeBool(key, Boolean::class.safeCast(defValue) ?: false)
            }

            Int::class -> {
                kv.decodeInt(key, Int::class.safeCast(defValue) ?: 0)
            }

            Long::class -> {
                kv.decodeLong(key, Long::class.safeCast(defValue) ?: 0L)
            }

            Float::class -> {
                kv.decodeFloat(key, Float::class.safeCast(defValue) ?: 0.0F)
            }

            Double::class -> {
                kv.decodeDouble(key, Double::class.safeCast(defValue) ?: 0.0)
            }

            ByteArray::class -> {
                kv.decodeBytes(key, ByteArray::class.safeCast(defValue) ?: byteArrayOf())
            }

            String::class -> {
                kv.decodeString(key, String::class.safeCast(defValue) ?: "")
            }

            else -> {
                kv.decodeString(key, String::class.safeCast(defValue) ?: "")
            }
        }
        return kotlin.runCatching { clazz.cast(value) }.getOrDefault(defValue)
    }

    override fun setValue(thisRef: IMMKVDelegate, property: KProperty<*>, value: T) {
        if (value == null) return
        val mmkv = thisRef.mmkv()
        val key = property.name
        when (value) {
            is Boolean -> mmkv.encode(key, value)
            is Int -> mmkv.encode(key, value)
            is Long -> mmkv.encode(key, value)
            is Float -> mmkv.encode(key, value)
            is Double -> mmkv.encode(key, value)
            is ByteArray -> mmkv.encode(key, value)
            is String -> mmkv.encode(key, value)
        }
    }

}