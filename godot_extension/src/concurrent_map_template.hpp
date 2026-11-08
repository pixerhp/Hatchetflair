/*  CONCURRENT_MAP_TEMPLATE OVERVIEW
    A template for a concurrent (thread safe) map, primarily for use in chunks map classes.
*/

#pragma once

#include <functional>
#include <map>
#include <mutex>
#include <optional>
#include <utility>
#include <vector>

template <typename Key, typename Value, typename Compare = std::less<Key>>
class ConcurrentMap {
    private:
        mutable std::mutex mutex;
        std::map<Key, Value, Compare> data;

    public:
        explicit ConcurrentMap(Compare compare = Compare{}) : data(std::move(compare)) {}

        std::vector<Key> keys() const {
            std::lock_guard<std::mutex> lock(mutex);
            std::vector<Key> result;
            result.reserve(data.size());
            for (const auto& entry : data) {
                result.push_back(entry.first);
            }
            return result;
        }

        bool contains(const Key& key) const {
            std::lock_guard<std::mutex> lock(mutex);
            return data.find(key) != data.end();
        }
        std::vector<bool> contains(const std::vector<Key>& keys) const {
            std::lock_guard<std::mutex> lock(mutex);
            std::vector<bool> result;
            result.reserve(keys.size());
            for (const auto& key : keys) {
                result.push_back(data.find(key) != data.end());
            }
            return result;
        }

        std::optional<Value> get(const Key& key) const {
            std::lock_guard<std::mutex> lock(mutex);
            const auto it = data.find(key);
            if (it == data.end()) {
                return std::nullopt;
            }
            return it->second;
        }
        std::vector<std::optional<Value>> get(const std::vector<Key>& keys) const {
            std::lock_guard<std::mutex> lock(mutex);
            std::vector<std::optional<Value>> result;
            result.reserve(keys.size());
            for (const auto& key : keys) {
                const auto it = data.find(key);
                if (it == data.end()) {
                    result.emplace_back(std::nullopt);
                } else {
                    result.emplace_back(it->second);
                }
            }
            return result;
        }

        void insert_or_assign(std::pair<Key, Value> entry) {
            std::lock_guard<std::mutex> lock(mutex);
            data.insert_or_assign(std::move(entry.first), std::move(entry.second));
        }
        void insert_or_assign(const std::vector<std::pair<Key, Value>>& entries) {
            std::lock_guard<std::mutex> lock(mutex);
            for (const auto& [key, value] : entries) {
                data.insert_or_assign(key, value);
            }
        }

        // (NOTE: std::map's erase method can return the number of elements erased if needed.)
        void erase(const Key& key) {
            std::lock_guard<std::mutex> lock(mutex);
            data.erase(key);
        }
        void erase(const std::vector<Key>& keys) {
            std::lock_guard<std::mutex> lock(mutex);
            for (const auto& key : keys) {
                data.erase(key);
            }
        }
};
