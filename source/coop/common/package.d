/**
 * Copyright: Copyright 2017 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop-common/blob/master/LICENSE, MIT License)
 */
module coop.common;

import vibe.data.json;
import std.typecons: Nullable;

interface ModelAPI
{
    import vibe.web.common;
    @path("/version") @property GetVersionResult getVersion();
    @path("/information") @property GetInformationResult getInformation();

    @path("/binders") @property GetBinderCategoriesResult getBinderCategories();
    @path("/binders/:binder/recipes") @queryParam("query", "query")
    @queryParam("migemo", "migemo") @queryParam("rev", "rev") @queryParam("key", "sort") @queryParam("fields", "fields")
    GetRecipesResult getBinderRecipes(string _binder, string query="",
                                      bool migemo=false, bool rev=false, string key = "default", string fields = "");

    @path("/skills") @property GetSkillCategoriesResult getSkillCategories();
    @path("/skills/:skill/recipes") @queryParam("query", "query")
    @queryParam("migemo", "migemo") @queryParam("rev", "rev") @queryParam("key", "sort") @queryParam("fields", "fields")
    GetRecipesResult getSkillRecipes(string _skill, string query="",
                                     bool migemo=false, bool rev=false, string key = "default", string fields = "");

    @path("/buffers") @property BufferLink[][string] getBuffers();

    @path("/recipes") @queryParam("migemo", "migemo") @queryParam("rev", "rev") @queryParam("key", "sort") @queryParam("fields", "fields")
    GetRecipesResult getRecipes(string query="", bool migemo=false, bool rev=false, string key = "default", string fields = "");

    @path("/items") @queryParam("migemo", "migemo") @queryParam("onlyProducts", "only-products") @queryParam("fromIngredients", "from-ingredients")
    GetItemsResult getItems(string query="", bool migemo=false, bool onlyProducts=false, bool fromIngredients=false);

    @path("/recipes/:recipe") RecipeInfo getRecipe(string _recipe);

    // 調達価格なしの場合
    @path("/items/:item") ItemInfo getItem(string _item);
    // 調達価格ありの場合
    @path("/items/:item") ItemInfo postItem(string _item, int[string] 調達価格 = null);

    @path("/menu-recipes/options") GetMenuRecipeOptionsResult getMenuRecipeOptions();

    @path("/menu-recipes/preparation") PostMenuRecipePreparationResult postMenuRecipePreparation(string[] 作成アイテム);
    @path("/menu-recipes")
    PostMenuRecipeResult postMenuRecipe(int[string] 作成アイテム, int[string] 所持アイテム, string[string] 使用レシピ, string[] 直接調達アイテム);
}

enum SortOrder: string
{
    ByDefault = "default",
    BySkill = "skill",
    ByName = "name",
}

enum ItemType: string
{
    UNKNOWN = "不明", Others = "その他", Food = "食べ物", Drink = "飲み物",
    Liquor = "酒", Expendable = "消耗品", Weapon = "武器", Armor = "防具",
    Bullet = "弾", Shield = "盾", Asset = "アセット",
}

enum PetFoodType: string
{
    UNKNOWN = "不明", Food = "食べ物", Meat = "肉食物", Weed = "草食物",
    Drink = "飲み物", Liquor = "酒", Medicine = "薬", Metal = "金属",
    Stone = "石", Bone = "骨", Crystal = "クリスタル", Wood = "木",
    Leather = "皮", Paper = "紙", Cloth = "布", Others = "その他",
    NoEatable = "犬も喰わない",
}

struct GetVersionResult
{
    @name("version") string version_;
}

struct GetInformationResult
{
    string message;
    string oldestSupportedRelease;
    string latestRelease;
}

struct GetBinderCategoriesResult
{
    BinderLink[] バインダー一覧;
}

struct GetRecipesResult
{
    RecipeLink[] レシピ一覧;
}

struct GetSkillCategoriesResult
{
    SkillLink[] スキル一覧;
}

struct GetItemsResult
{
    ItemLink[] アイテム一覧;
}

struct GetMenuRecipeOptionsResult
{
    static struct RetElem{
        ItemLink 生産アイテム;
        RecipeLink[] レシピ候補;
    }
    RetElem[] 選択可能レシピ;
}

struct PostMenuRecipePreparationResult
{
    RecipeLink[] 必要レシピ;
    ItemLink[] 必要素材;
}

struct PostMenuRecipeResult
{
    RecipeNumberLink[] 必要レシピ;
    ItemNumberLink[] 必要素材;
    ItemNumberLink[] 余り物;
}

struct BinderLink
{
    string バインダー名;
    string レシピ一覧;
}

struct SkillLink
{
    string スキル名;
    string レシピ一覧;
}

struct SkillNumberLink
{
    string スキル名;
    string レシピ一覧;
    double スキル値;
}

struct ItemLink
{
    string アイテム名;
    string 詳細;
    Json[string] 追加情報;
}

struct RecipeLink
{
    string レシピ名;
    string 詳細;
    Json[string] 追加情報;
}

struct BufferLink
{
    string バフ名;
    string 詳細;
}

struct ItemNumberLink
{
    string アイテム名;
    string 詳細;
    Json[string] 追加情報;
    int 個数;
}

struct RecipeNumberLink
{
    string レシピ名;
    string 詳細;
    Json[string] 追加情報;
    int コンバイン数;
}

struct RecipeInfo
{
    string レシピ名;
    ItemNumberLink[] 材料;
    ItemNumberLink[] 生成物;
    string[] テクニック;
    double[string] 必要スキル;
    bool レシピ必須;
    bool ギャンブル型;
    bool ペナルティ型;
    BinderLink[] 収録バインダー;
    string 備考;
}

struct SpecialPropertyInfo
{
    string 略称;
    string 詳細;
}

struct PetFoodInfo
{
    string 種別 = "不明";
    double 効果;
}

struct ItemInfo
{
    string アイテム名;
    string 英名;
    double 重さ;
    uint NPC売却価格;
    uint 参考価格;
    string info;
    SpecialPropertyInfo[] 特殊条件;
    bool 転送可;
    bool スタック可;
    PetFoodInfo ペットアイテム;
    BinderLink[] レシピ;
    string 備考;
    string アイテム種別 = "不明";

    Nullable!FoodInfo 飲食物情報;
    Nullable!WeaponInfo 武器情報;
    Nullable!ArmorInfo 防具情報;
    Nullable!BulletInfo 弾情報;
    Nullable!ShieldInfo 盾情報;
    // Nullable!ExpendableInfo 消耗品情報;
}

struct FoodInfo
{
    double 効果;
    Nullable!FoodBufferInfo 付加効果;
}

struct FoodBufferInfo
{
    string バフ名;
    string バフグループ;
    int[string] 効果;
    string その他効果;
    uint 効果時間;
    string 備考;
}

struct DamageInfo
{
    string 状態;
    double 効果;
}

struct ShipLink
{
    string シップ名;
    string 詳細;
}

struct WeaponInfo
{
    DamageInfo[] 攻撃力;
    int 攻撃間隔;
    double 有効レンジ;
    SkillNumberLink[] 必要スキル;
    bool 両手装備;
    string 装備スロット;
    ShipLink[] 装備可能シップ;
    string 素材;
    string 消耗タイプ;
    int 耐久;
    double[string] 追加効果;
    int[string] 付加効果;
    string[] 効果アップ;
    bool 魔法チャージ;
    bool 属性チャージ;
}

struct ArmorInfo
{
    DamageInfo[] アーマークラス;
    SkillNumberLink[] 必要スキル;
    string 装備スロット;
    ShipLink[] 装備可能シップ;
    string 素材;
    string 消耗タイプ;
    int 耐久;
    double[string] 追加効果;
    string 付加効果; //
    string[] 効果アップ; //
    bool 魔法チャージ;
    bool 属性チャージ;
}

struct BulletInfo
{
    double ダメージ;
    double 有効レンジ;
    int 角度補正角;
    ShipLink[] 使用可能シップ;
    SkillNumberLink[] 必要スキル;
    double[string] 追加効果;
    string 付与効果;
}

struct ShieldInfo
{
    DamageInfo[] アーマークラス;
    SkillNumberLink[] 必要スキル;
    int 回避;
    ShipLink[] 使用可能シップ;
    string 素材;
    string 消耗タイプ;
    int 耐久;
    double[string] 追加効果;
    string 付加効果;
    string[] 効果アップ;
    bool 魔法チャージ;
    bool 属性チャージ;
}
