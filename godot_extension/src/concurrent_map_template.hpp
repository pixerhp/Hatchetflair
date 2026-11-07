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

        std::optional<Value> get(const Key& key) const {
            std::lock_guard<std::mutex> lock(mutex);
            const auto it = data.find(key);
            if (it == data.end()) {
                return std::nullopt;
            }
            return it->second;
        }

        void insert_or_assign(Key key, Value value) {
            std::lock_guard<std::mutex> lock(mutex);
            data.insert_or_assign(std::move(key), std::move(value));
        }

        bool erase(const Key& key) {
            std::lock_guard<std::mutex> lock(mutex);
            return data.erase(key) != 0;
        }
};
