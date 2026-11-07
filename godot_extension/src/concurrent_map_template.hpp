#pragma once

#include <functional>
#include <map>
#include <mutex>
#include <optional>
#include <utility>

template <typename Key, typename Value, typename Compare = std::less<Key>>
class ConcurrentMap {
    private:
        mutable std::mutex mutex;
        std::map<Key, Value, Compare> data;

    public:
        explicit ConcurrentMap(Compare compare = Compare{}) : data(std::move(compare)) {}

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
