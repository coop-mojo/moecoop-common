/**
   MoeCoop
   Copyright (C) 2016  Mojo

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
module coop.item;

import std.algorithm;
import std.container.rbtree;
import std.conv;
import std.exception;
import std.file;
import std.json;
import std.range;
import std.typecons;

import coop.util;


enum PetFoodType
{
    Food,
    Meat,
    Weed,
    Drink,
    Liquor,
    Medicine,
    Metal,
    Stone,
    Bone,
    Crystal,
    Wood,
    Leather,
    Paper,
    Cloth,
    Others,
}

auto toString(PetFoodType t)
{
    final switch(t) with(PetFoodType)
    {
    case Food:     return "食べ物";
    case Meat:     return "肉食物";
    case Weed:     return "草食物";
    case Drink:    return "飲み物";
    case Liquor:   return "お酒";
    case Medicine: return "薬";
    case Metal:    return "金属";
    case Stone:    return "石";
    case Bone:     return "骨";
    case Crystal:  return "クリスタル";
    case Wood:     return "木";
    case Leather:  return "皮";
    case Paper:    return "紙";
    case Cloth:    return "布";
    case Others:   return "その他";
    }
}


enum SpecialProperty: ushort
{
    NT = 0b00000000000001,
    OP = 0b00000000000010,
    CS = 0b00000000000100,
    CR = 0b00000000001000,
    PM = 0b00000000010000,
    NC = 0b00000000100000,
    NB = 0b00000001000000,
    ND = 0b00000010000000,
    CA = 0b00000100000000,
    DL = 0b00001000000000,
    TC = 0b00010000000000,
    LO = 0b00100000000000,
    AL = 0b01000000000000,
    WA = 0b10000000000000,
}

auto toString(SpecialProperty sp)
{
    with(SpecialProperty)
    {
        auto propMap = [
            NT: "他のプレイヤーにトレードで渡せない",
            OP: "一人一個のみ",
            CS: "売ることができない",
            CR: "修理できない",
            PM: "消耗度による威力計算を行わない",
            NC: "修理による最大耐久度低下を行わない",
            NB: "耐久度による武器の破壊が行われない",
            ND: "死亡時ドロップしない",
            CA: "カオスエイジで死亡しても消えない",
            DL: "死亡すると消える",
            TC: "タイムカプセルボックスに入れることが出来ない",
            LO: "ログアウトすると消える",
            AL: "現在のエリア限定",
            WA: "WarAgeでは性能が低下する",
            ];
        return propMap[sp];
    }
}

enum ItemType
{
    Food,
    Drink,
    Weapon,
    Armor,
    Other,
}

/// アイテム一般の情報
struct Item
{
    dstring name;
    dstring ename;
    real weight;
    uint price;
    dstring info;
    SpecialProperty properties;
    bool transferable;
    bool stackable;
    real[PetFoodType] petFoodInfo;
    dstring remarks;
    ItemType type;
}

auto readItems(string fname, string sysBase, string userBase)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto items = res.object;
    return items.keys.map!(key =>
                           tuple(key.to!dstring,
                                 key.toItem(items[key].object)));
}

auto toItem(string s, JSONValue[string] json)
{
    Item item;
    with(item) {
        name = s.to!dstring;
        ename = json["英名"].str.to!dstring;
        price = json["NPC売却価格"].integer.to!uint;
        weight = json["重さ"].floating.to!real;
        info = json["info"].str.to!dstring;
        transferable = json["転送できる"].toBool;
        stackable = json["スタックできる"].toBool;
        if (auto petFood = "ペットアイテム" in json)
        {
            petFoodInfo = (*petFood).object.toPetFoodInfo;
        }

        if (auto props = "特殊条件" in json)
        {
            properties = (*props).array.toSpecialProperties;
        }
    }
    return item;
}

auto toSpecialProperties(JSONValue[] vals)
{
    auto props = vals.map!"a.str".map!(s => s.to!SpecialProperty).array;
    return props.reduce!((a, b) => a|b).to!SpecialProperty;
}

auto toPetFoodInfo(JSONValue[string] vals)
{
    with(PetFoodType) {
        auto FoodTypeMap = [
            "食べ物": Food,
            "肉食物": Meat,
            "草食物": Weed,
            "飲み物": Drink,
            "お酒": Liquor,
            "薬": Medicine,
            "金属": Metal,
            "石": Stone,
            "骨": Bone,
            "クリスタル": Crystal,
            "木": Wood,
            "皮": Leather,
            "紙": Paper,
            "布": Cloth,
            "その他": Others,
            ];
        return vals.keys.map!(k => tuple(FoodTypeMap[k], vals[k].floating.to!real)).assocArray;
    }
}

/// 料理固有の情報
struct Food
{
    dstring name;
    real effect;
    dstring additionalEffect;
}

auto readFoods(string fname, string sysBase)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto foods = res.object;
    return foods.keys.map!(key =>
                           tuple(key.to!dstring,
                                 key.toFood(foods[key].object)));
}

auto toFood(string s, JSONValue[string] json)
{
    Food food;
    with(food) {
        name = s.to!dstring;
        effect = json["効果"].floating.to!real;
        if (auto addition = "付加効果" in json)
        {
            additionalEffect = (*addition).str.to!dstring;
        }
    }
    return food;
}

/// 飲食バフのグループ
enum AdditionalEffectGroup
{
    A, B1, B2, C1, C2, D1, D2, D3, D4, E, F,
}

/// 飲食バフの効果情報
struct AdditionalEffect
{
    dstring name;
    AdditionalEffectGroup group;
    int[dstring] effects;
    uint duration;
    dstring remarks;
}

auto readFoodEffects(string fname, string sysBase)
{
    auto res = fname.readText.parseJSON;
    enforce(res.type == JSON_TYPE.OBJECT);
    auto effects = res.object;
    return effects.keys.map!(key =>
                             tuple(key.to!dstring,
                                   key.toFoodEffect(effects[key].object)));
}

auto toFoodEffect(string s, JSONValue[string] json)
{
    AdditionalEffect effect;
    with(effect) {
        name = s.to!dstring;
        effects = json["効果"].object.toStatusEffect;
        duration = json["効果時間"].integer.to!uint;
        group = json["グループ"].str.to!AdditionalEffectGroup;
        if (auto rem = "備考" in json)
        {
            remarks = (*rem).str.to!dstring;
        }
    }
    return effect;
}

auto toStatusEffect(JSONValue[string] json)
{
    return json.keys.map!((key) { return tuple(key.to!dstring, json[key].integer.to!int); }).assocArray;
}