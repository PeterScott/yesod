{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes, TypeFamilies, TemplateHaskell, MultiParamTypeClasses #-}
import Yesod.Core
import Yesod.Form
import Yesod.Form.MassInput
import Control.Applicative
import Data.Text (Text, pack)
import Network.Wai.Handler.Warp (run)

data Fruit = Apple | Banana | Pear
    deriving (Show, Enum, Bounded, Eq)

fruits :: [(Text, Fruit)]
fruits = map (\x -> (pack $ show x, x)) [minBound..maxBound]

myForm = fixType $ runFormGet $ renderDivs $ pure (,,,,,,,,)
    <*> areq boolField "Bool field" Nothing
    <*> aopt boolField "Opt bool field" Nothing
    <*> areq textField "Text field" Nothing
    <*> areq (selectField fruits) "Select field" Nothing
    <*> aopt (selectField fruits) "Opt select field" Nothing
    <*> areq (multiSelectField fruits) "Multi select field" Nothing
    <*> aopt (multiSelectField fruits) "Opt multi select field" Nothing
    <*> aopt intField "Opt int field" Nothing
    <*> aopt (radioField fruits) "Opt radio" Nothing

data HelloForms = HelloForms
type Handler = GHandler HelloForms HelloForms

fixType :: Handler a -> Handler a
fixType = id

instance RenderMessage HelloForms FormMessage where
    renderMessage _ _ = defaultFormMessage

instance Yesod HelloForms where
    approot _ = ""

mkYesod "HelloForms" [parseRoutes|
/ RootR GET
/mass MassR GET
|]

getRootR = do
    ((res, form), enctype) <- myForm
    defaultLayout [whamlet|
<p>Result: #{show res}
<form enctype=#{enctype}>
    ^{form}
    <div>
        <input type=submit>
<p>
    <a href=@{MassR}>See the mass form
|]

myMassForm = fixType $ runFormGet $ renderTable $ inputList "People" massTable
    (\x -> (,)
        <$> areq textField "Name" (fmap fst x)
        <*> areq intField "Age" (fmap snd x)) (Just [("Michael", 26)])

getMassR = do
    ((res, form), enctype) <- myMassForm
    defaultLayout [whamlet|
<p>Result: #{show res}
<form enctype=#{enctype}>
    <table>
        ^{form}
    <div>
        <input type=submit>
<p>
    <a href=@{RootR}>See the regular form
|]

main = toWaiApp HelloForms >>= run 3000
